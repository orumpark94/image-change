import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const s3 = new S3Client({ region: "ap-northeast-2" });

// 허용된 확장자 및 MIME 타입
const ALLOWED_EXTENSIONS = ["jpg", "jpeg", "png", "webp"];
const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { filename, mimetype, size } = body;

    if (!filename || !mimetype || !size) {
      return { statusCode: 400, body: "Missing parameters" };
    }

    const ext = filename.split(".").pop().toLowerCase();
    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      return { statusCode: 400, body: "Invalid file extension" };
    }

    if (!ALLOWED_MIME_TYPES.includes(mimetype)) {
      return { statusCode: 400, body: "Invalid MIME type" };
    }

    if (size > 5 * 1024 * 1024) { // 5MB 제한
      return { statusCode: 400, body: "File too large" };
    }

    const key = `uploads/${Date.now()}-${filename}`;
    const command = new PutObjectCommand({
      Bucket: process.env.BUCKET_NAME,
      Key: key,
      ContentType: mimetype,
    });

    const url = await getSignedUrl(s3, command, { expiresIn: 60 }); // Presigned URL 1분 유효

     return {
       statusCode: 200,
       body: JSON.stringify({ url, key }),
       headers: {
         "Content-Type": "application/json",
         "Access-Control-Allow-Origin": process.env.ALLOWED_ORIGIN,                // ✅ CORS 허용 (운영 시 도메인으로 제한 권장)
         "Access-Control-Allow-Headers": "Content-Type"
       }
     };

  } catch (err) {
    console.error("Error generating presigned URL:", err);
    return { statusCode: 500, body: "Internal server error" };
  }
};
