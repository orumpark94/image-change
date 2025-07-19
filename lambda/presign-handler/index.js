import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3 = new S3Client({ region: "ap-northeast-2" });

const ALLOWED_EXTENSIONS = ["jpg", "jpeg", "png", "webp"];
const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];

const corsHeaders = {
  "Access-Control-Allow-Origin": process.env.ALLOWED_ORIGIN,
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "GET,OPTIONS",
  "Content-Type": "application/json"
};

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { filename, mimetype, size } = body;

    if (!filename || !mimetype || !size) {
      return { statusCode: 400, body: JSON.stringify({ message: "Missing parameters" }), headers: corsHeaders };
    }

    const ext = filename.split(".").pop().toLowerCase();
    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      return { statusCode: 400, body: JSON.stringify({ message: "Invalid file extension" }), headers: corsHeaders };
    }

    if (!ALLOWED_MIME_TYPES.includes(mimetype)) {
      return { statusCode: 400, body: JSON.stringify({ message: "Invalid MIME type" }), headers: corsHeaders };
    }

    if (size > 5 * 1024 * 1024) {
      return { statusCode: 400, body: JSON.stringify({ message: "File too large" }), headers: corsHeaders };
    }

    const key = `uploads/${Date.now()}-${filename}`;
    const command = new PutObjectCommand({
      Bucket: process.env.BUCKET_NAME,
      Key: key,
      ContentType: mimetype
    });

    const url = await getSignedUrl(s3, command, { expiresIn: 60 });

    return {
      statusCode: 200,
      body: JSON.stringify({ url, key }),
      headers: corsHeaders
    };

  } catch (err) {
    console.error("Error generating presigned URL:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal server error" }),
      headers: corsHeaders
    };
  }
};
