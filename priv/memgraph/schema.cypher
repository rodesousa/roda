// ============================================
// Memgraph Schema - Roda RAG
// ============================================
// Based on: ARCHITECTURE_MEMGRAPH_RAG_PRODUCTION.md
// Date: 2025-10-08

// ============================================
// 1. CONSTRAINTS
// ============================================

// Chunk constraints
CREATE CONSTRAINT ON (c:Chunk) ASSERT c.id IS UNIQUE;
CREATE CONSTRAINT ON (c:Chunk) ASSERT c.user_id IS NOT NULL;
CREATE CONSTRAINT ON (c:Chunk) ASSERT EXISTS(c.embedding);

// Entity constraints
CREATE CONSTRAINT ON (e:Entity) ASSERT e.id IS UNIQUE;
CREATE CONSTRAINT ON (e:Entity) ASSERT e.user_id IS NOT NULL;
CREATE CONSTRAINT ON (e:Entity) ASSERT EXISTS(e.embedding);

// ============================================
// 2. VECTOR INDEXES
// ============================================

// Chunk vector index (1536 dims for text-embedding-ada-002)
CREATE VECTOR INDEX chunk_vector
ON :Chunk(embedding)
WITH CONFIG {
    'dimension': 1536,
    'capacity': 500000,
    'metric': 'cos'
};

// Entity vector index
CREATE VECTOR INDEX entity_vector
ON :Entity(embedding)
WITH CONFIG {
    'dimension': 1536,
    'capacity': 100000,
    'metric': 'cos'
};

// ============================================
// 3. PROPERTY INDEXES
// ============================================

// Chunk indexes
CREATE INDEX ON :Chunk(user_id);
CREATE INDEX ON :Chunk(conversation_id);
CREATE INDEX ON :Chunk(position);

// Entity indexes
CREATE INDEX ON :Entity(user_id);
CREATE INDEX ON :Entity(type);
CREATE INDEX ON :Entity(name_hash);
CREATE INDEX ON :Entity(normalized_name);

// ============================================
// 4. EXAMPLE NODES (for reference)
// ============================================

// Example Chunk node
// CREATE (c:Chunk {
//     id: "chunk-uuid",
//     text: "Marie Dupont est Project Manager...",
//     contextual_text: "Marie Dupont est Project Manager chez Acme Corp...",
//     conversation_id: "conv-uuid",
//     user_id: "user-uuid",
//     position: 0,
//     embedding: [0.1, -0.2, ...],  // 1536 dims
//     embedding_model: "text-embedding-ada-002",
//     embedding_dims: 1536,
//     created: timestamp(),
//     version: 1
// })

// Example Entity node
// CREATE (e:Entity {
//     id: "entity-uuid",
//     name: "Marie Dupont",
//     normalized_name: "marie_dupont",
//     name_hash: "abc123def456",
//     type: "PERSON",
//     description: "Project Manager at Acme Corp",
//     user_id: "user-uuid",
//     embedding: [0.1, -0.2, ...],  // 1536 dims
//     embedding_model: "text-embedding-ada-002",
//     embedding_dims: 1536,
//     mentions: 1,
//     aliases: [],
//     confidence_score: 1.0,
//     dedup_method: "new",
//     created: timestamp(),
//     updated: timestamp(),
//     version: 1
// })

// Example relation Chunk -> Entity
// CREATE (c:Chunk)-[:MENTIONS {
//     confidence: 0.95,
//     mention_count: 2
// }]->(e:Entity)
