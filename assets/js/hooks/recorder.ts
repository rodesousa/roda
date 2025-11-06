/**
 * Audio Recorder Hook for Phoenix LiveView
 *
 * Records audio in 30-second chunks and uploads to MinIO storage.
 *
 * Key Features:
 * - Automatic chunking every 30 seconds
 * - Pause/Resume with MediaRecorder restart (prevents file corruption)
 * - Automatic upload to /api/chunks/upload
 * - Valid WebM files for each chunk
 *
 * Architecture:
 * - Each pause creates a new chunk by stopping MediaRecorder
 * - Resume creates a NEW MediaRecorder (reuses existing stream)
 * - This ensures each chunk is a valid, standalone WebM file
 *
 */

type Conversation = {
  id: string
}

export const Recorder = {
  mounted() {
    this.mediaRecorder = null;
    this.chunks = [];
    this.stream = null;
    this.isPaused = false; // Track pause state manually
    this.conversation = null;
    this.audioContext = null;
    this.analyser = null;
    this.dataArray = null;
    this.animationId = null;
    this.isTesting = false;
    this.pendingUploads = 0; // Track uploads in progress
    this.isStopping = false; // Track if we're in the process of stopping
    this.lastLevelUpdate = 0; // Timestamp of last level update sent
    this.levelUpdateThrottle = 100; // Minimum 100ms between updates (10 updates/sec max)
    this.chunkCount = 0; // Track total number of chunks uploaded

    // Listen for events from LiveView
    this.handleEvent("start_recording", (conversation: Conversation) => this.startRecording(conversation));
    this.handleEvent("pause_recording", () => this.pauseRecording());
    this.handleEvent("resume_recording", () => this.resumeRecording());
    this.handleEvent("stop_recording", () => this.stopRecording());
    this.handleEvent("start_mic_test", () => this.startMicTest());
    this.handleEvent("stop_mic_test", () => this.stopMicTest());
  },

  /**
   * Starts audio recording with 30-second chunks.
   *
   * Reuses existing stream if available (after pause/resume).
   * Creates new MediaRecorder instance each time.
   */
  async startRecording(conversation: Conversation) {
    try {
      this.conversation = conversation;
      this.pendingUploads = 0; // Reset counter
      this.isStopping = false;
      this.chunkCount = 0; // Reset chunk counter

      // Request microphone access if not already available
      if (!this.stream) {
        this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      }

      // Choose best supported format
      const mimeType = this.getSupportedMimeType();

      // Create MediaRecorder with 30-second chunks
      this.mediaRecorder = new MediaRecorder(this.stream, { mimeType });

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.uploadChunk(event.data);
        }
      };

      this.mediaRecorder.onstop = () => {
        // Only close stream if fully stopped (not paused)
        if (!this.isPaused) {
          this.stream.getTracks().forEach(track => track.stop());
          this.stream = null;
        }
      };

      // Start recording with 30-second chunks
      this.mediaRecorder.start(30000);
      this.isPaused = false;

      this.pushEvent("recording_started", { mimeType });
    } catch (error) {
      this.pushEvent("recording_error", { error: error.message });
    }
  },

  /**
   * Pauses recording by stopping MediaRecorder.
   *
   * IMPORTANT: We use stop() instead of pause() to ensure
   * the current chunk is properly finalized with WebM headers.
   *
   * The stream remains open for quick resume.
   */
  pauseRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state === "recording") {
      // Stop MediaRecorder to finalize current chunk properly
      this.isPaused = true;
      this.mediaRecorder.stop();
      this.pushEvent("recording_paused", {});
    }
  },

  /**
   * Resumes recording by creating a NEW MediaRecorder.
   *
   * Why new MediaRecorder?
   * - Ensures each chunk is a valid WebM file
   * - Prevents corruption from partial data
   * - Reuses existing stream (no permission re-request)
   */
  resumeRecording() {
    if (this.isPaused && this.stream) {
      // Restart a new MediaRecorder with existing stream

      const mimeType = this.getSupportedMimeType();

      // Crée un nouveau MediaRecorder sur le même stream (ne pas reset les compteurs)
      this.mediaRecorder = new MediaRecorder(this.stream, { mimeType });

      // Gère la réception des données
      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
          this.uploadChunk(event.data);
        }
      };

      // Si on stop le recorder, on ferme le stream seulement si c’est un vrai arrêt
      this.mediaRecorder.onstop = () => {
        if (!this.isPaused && !this.isStopping) {
          this.stream.getTracks().forEach(track => track.stop());
          this.stream = null;
        }
      };

      // Redémarre l’enregistrement en chunk de 30s
      this.mediaRecorder.start(30000);
      this.isPaused = false;
      this.pushEvent("recording_resumed", {});
    }
  },

  async stopRecording() {
    this.isStopping = true;

    if (this.mediaRecorder && this.mediaRecorder.state !== "inactive") {
      // stop() automatically triggers ondataavailable for final chunk
      this.isPaused = false;
      this.mediaRecorder.stop();
    }

    // Wait for all pending uploads to complete
    await this.waitForUploadsToComplete();

    this.isStopping = false;
    this.pushEvent("recording_stopped", {
      total_chunks: this.chunkCount
    });
  },

  /**
   * Waits for all pending uploads to complete.
   * Polls every 100ms until pendingUploads reaches 0.
   */
  async waitForUploadsToComplete() {
    const maxWaitTime = 30000; // Maximum 30 seconds
    const checkInterval = 100; // Check every 100ms
    let elapsedTime = 0;

    while (this.pendingUploads > 0 && elapsedTime < maxWaitTime) {
      await new Promise(resolve => setTimeout(resolve, checkInterval));
      elapsedTime += checkInterval;
    }

    if (this.pendingUploads > 0) {
      console.warn(`Still ${this.pendingUploads} uploads pending after ${maxWaitTime}ms`);
    }
  },

  /**
   * Uploads audio chunk to Phoenix backend.
   *
   * @param {Blob} blob - Audio data from MediaRecorder
   *
   * POST /api/chunks/upload
   * - chunk: binary audio file
   * - timestamp: ISO datetime
   */
  async uploadChunk(blob) {
    // Increment counters
    this.pendingUploads++;
    this.chunkCount++;

    const formData = new FormData();
    const filename = `chunk-${Date.now()}.${this.getExtension()}`;

    formData.append("chunk", blob, filename);
    formData.append("timestamp", new Date().toISOString());
    formData.append("conversation_id", this.conversation.id);

    try {
      const response = await fetch("/api/chunks/upload", {
        method: "POST",
        body: formData,
      });

      if (response.ok) {
        const data = await response.json();
        this.pushEvent("chunk_uploaded", { path: data.path });
      } else {
        this.pushEvent("chunk_upload_error", { status: response.status });
      }
    } catch (error) {
      this.pushEvent("chunk_upload_error", { error: error.message });
    } finally {
      // Decrement pending uploads counter
      this.pendingUploads--;
    }
  },

  getSupportedMimeType() {
    const types = [
      "audio/webm",
      "audio/webm;codecs=opus",
      "audio/wav",
      "video/mp4",
    ];

    for (const type of types) {
      if (MediaRecorder.isTypeSupported(type)) {
        return type;
      }
    }

    return ""; // Browser will use default
  },

  getExtension() {
    const mimeType = this.mediaRecorder?.mimeType || "audio/webm";

    if (mimeType.includes("webm")) return "webm";
    if (mimeType.includes("wav")) return "wav";
    if (mimeType.includes("mp4")) return "mp4";

    return "webm";
  },

  /**
   * Starts microphone test with audio level visualization.
   *
   * Requests microphone permission and analyzes audio levels in real-time.
   */
  async startMicTest() {
    try {
      this.isTesting = true;

      // Request microphone access
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });

      // Initialize Web Audio API for audio analysis
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      this.analyser = this.audioContext.createAnalyser();
      this.analyser.fftSize = 1024;
      this.analyser.smoothingTimeConstant = 0.8;

      // Connect stream to analyser
      const source = this.audioContext.createMediaStreamSource(this.stream);
      source.connect(this.analyser);

      // Initialize data array
      this.dataArray = new Uint8Array(this.analyser.frequencyBinCount);

      // Start visualization loop
      this.visualizeAudioLevel();

      this.pushEvent("mic_test_started", {});
    } catch (error) {
      console.error("Mic test error:", error);
      this.pushEvent("mic_test_error", { error: error.message });
    }
  },

  /**
   * Stops microphone test and releases resources.
   */
  stopMicTest() {
    this.isTesting = false;

    // Stop animation loop
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
      this.animationId = null;
    }

    // Close audio context
    if (this.audioContext) {
      this.audioContext.close();
      this.audioContext = null;
    }

    // Stop stream
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }

    this.analyser = null;
    this.dataArray = null;

    this.pushEvent("mic_test_stopped", {});
  },

  /**
   * Visualization loop that calculates audio level and updates DOM directly.
   *
   * Uses frequency data for more accurate volume detection.
   */
  visualizeAudioLevel() {
    if (!this.analyser || !this.dataArray || !this.isTesting) {
      return;
    }

    // Get frequency data (better for volume detection)
    this.analyser.getByteFrequencyData(this.dataArray);

    // Calculate average volume across all frequencies
    let sum = 0;
    for (let i = 0; i < this.dataArray.length; i++) {
      sum += this.dataArray[i];
    }
    const average = sum / this.dataArray.length;

    // Normalize to 0-100 range with amplification
    // Amplify by 2.5x so normal speech shows 60-80% instead of 20-40%
    const displayLevel = Math.min((average / 128) * 100 * 2.5, 100);
    const roundedLevel = Math.round(displayLevel);

    // Update DOM directly (faster than sending to LiveView)
    this.updateAudioLevelUI(roundedLevel);

    // Continue animation loop
    this.animationId = requestAnimationFrame(() => this.visualizeAudioLevel());
  },

  /**
   * Updates the audio level UI elements directly in the DOM.
   */
  updateAudioLevelUI(level: number) {
    // Update level text
    const levelText = document.querySelector("#mic-test-level-text");
    if (levelText) {
      levelText.textContent = `${level}%`;
    }

    // Update progress bar value
    const progressBar = document.querySelector("#mic-test-progress");
    if (progressBar) {
      progressBar.value = level;

      // Change progress bar color based on level
      progressBar.classList.remove("progress-primary", "progress-warning");
      if (level > 20) {
        progressBar.classList.add("progress-primary");
      } else {
        progressBar.classList.add("progress-warning");
      }
    }

    // Show/hide "Voice detected!" badge
    const badge = document.querySelector("#mic-test-success-badge");
    if (badge) {
      // With 2.5x amplification, normal speech is 60-80%
      // So threshold at 20% = real 8% (silence is typically 5-10%)
      if (level > 20) {
        badge.classList.remove("hidden");
      } else {
        badge.classList.add("hidden");
      }
    }
  },

  destroyed() {
    this.isPaused = false;
    this.isTesting = false;
    this.pendingUploads = 0;
    this.isStopping = false;
    this.chunkCount = 0;

    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
    }

    if (this.mediaRecorder && this.mediaRecorder.state !== "inactive") {
      this.mediaRecorder.stop();
    }

    if (this.audioContext) {
      this.audioContext.close();
    }

    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }
  },
};
