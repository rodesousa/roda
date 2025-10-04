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
 * @see /AUDIO_RECORDING.md for full documentation
 */
export const Recorder = {
  mounted() {
    this.mediaRecorder = null;
    this.chunks = [];
    this.stream = null;
    this.isPaused = false; // Track pause state manually

    // Listen for events from LiveView
    this.handleEvent("start_recording", () => this.startRecording());
    this.handleEvent("pause_recording", () => this.pauseRecording());
    this.handleEvent("resume_recording", () => this.resumeRecording());
    this.handleEvent("stop_recording", () => this.stopRecording());
  },

  /**
   * Starts audio recording with 30-second chunks.
   *
   * Reuses existing stream if available (after pause/resume).
   * Creates new MediaRecorder instance each time.
   */
  async startRecording() {
    try {
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
      this.startRecording();
      this.pushEvent("recording_resumed", {});
    }
  },

  stopRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state !== "inactive") {
      // stop() automatically triggers ondataavailable for final chunk
      this.isPaused = false;
      this.mediaRecorder.stop();
      this.pushEvent("recording_stopped", {});
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
    const formData = new FormData();
    const filename = `chunk-${Date.now()}.${this.getExtension()}`;

    formData.append("chunk", blob, filename);
    formData.append("timestamp", new Date().toISOString());

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

  destroyed() {
    this.isPaused = false;
    if (this.mediaRecorder && this.mediaRecorder.state !== "inactive") {
      this.mediaRecorder.stop();
    }
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }
  },
};
