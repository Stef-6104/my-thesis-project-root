const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {PredictionServiceClient} = require("@google-cloud/aiplatform");

const client = new PredictionServiceClient({
  apiEndpoint: "us-central1-aiplatform.googleapis.com",
});

const PROJECT_ID = process.env.GCLOUD_PROJECT;
const LOCATION = "us-central1";
const MODEL = "gemini-embedding-001";

/**
 * Creates a text embedding using Vertex AI.
 *
 * @param {string} text Text to embed.
 * @param {string} taskType Vertex AI embedding task type.
 * @return {Promise<number[]>} The embedding vector.
 */
async function createEmbedding(text, taskType) {
  const endpoint =
    "projects/" + PROJECT_ID +
    "/locations/" + LOCATION +
    "/publishers/google/models/" + MODEL;

  const instance = {
    content: text,
    task_type: taskType,
  };

  const parameters = {
    outputDimensionality: 768,
  };

  const [response] = await client.predict({
    endpoint: endpoint,
    instances: [
      {
        structValue: instance,
      },
    ],
    parameters: {
      structValue: parameters,
    },
  });

  const prediction = response.predictions[0];

  const values =
    prediction.structValue.fields.embeddings
        .structValue.fields.values
        .listValue.values
        .map((value) => value.numberValue);

  if (values.length !== 768) {
    throw new Error(
        "Expected 768 dimensions, received " + values.length,
    );
  }

  return values;
}

/**
 * Generates an embedding for a document or query.
 *
 * @param {Object} request Firebase callable request.
 * @return {Promise<Object>} The embedding response.
 */
exports.generateEmbedding = onCall(
    {
      region: "us-central1",
      timeoutSeconds: 60,
      memory: "256MiB",
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "You must be signed in.",
        );
      }

      const data = request.data || {};
      const text = data.text;
      const taskType =
      data.taskType || "RETRIEVAL_DOCUMENT";

      if (!text || typeof text !== "string") {
        throw new HttpsError(
            "invalid-argument",
            "text is required.",
        );
      }

      if (
        taskType !== "RETRIEVAL_DOCUMENT" &&
      taskType !== "RETRIEVAL_QUERY"
      ) {
        throw new HttpsError(
            "invalid-argument",
            "Invalid embedding task type.",
        );
      }

      try {
        const embedding = await createEmbedding(
            text,
            taskType,
        );

        return {
          embedding: embedding,
          dimensions: embedding.length,
        };
      } catch (error) {
        console.error("Embedding error:", error);

        throw new HttpsError(
            "internal",
            "Failed to generate embedding.",
        );
      }
    },
);
