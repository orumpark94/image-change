import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3 = new S3Client({ region: "ap-northeast-2" });

const ALLOWED_EXTENSIONS = ["jpg", "jpeg", "png", "webp"];
const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];

const corsHeaders = {
  "Access-Control-Allow-Origin": process.env.ALLOWED_ORIGIN || "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "GET,OPTIONS",
  "Content-Type": "application/json"
};

export const handler = async (event) => {
  let body;

  // ✅ JSON 파싱 예외 처리
  try {
    body = event.body ? JSON.parse(event.body) : {};
  } catch (err) {
    console.error("Invalid JSON in request body:", err);
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Invalid request body" }),
      headers: corsHeaders
    };
  }

  const { filename, mimetype, size } = body;

  // ✅ 입력 유효성 검사
  if (!filename || !mimetype || !size) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Missing parameters" }),
      headers: corsHeaders
    };
  }

  const ext = filename.split(".").pop().toLowerCase();
  if (!ALLOWED_EXTENSIONS.includes(ext)) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Invalid file extension" }),
      headers: corsHeaders
    };
  }

  if (!ALLOWED_MIME_TYPES.includes(mimetype)) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Invalid MIME type" }),
      headers: corsHeaders
    };
  }

  if (size > 5 * 1024 * 1024) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "File too large" }),
      headers: corsHeaders
    };
  }

  // ✅ 환경변수 확인
  const bucket = process.env.BUCKET_NAME;
  if (!bucket) {
    console.error("BUCKET_NAME env var is missing");
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Server misconfiguration: BUCKET_NAME missing" }),
      headers: corsHeaders
    };
  }

  const key = `uploads/${Date.now()}-${filename}`;
  const command = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    ContentType: mimetype
  });

  try {
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
