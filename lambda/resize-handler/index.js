import { S3Client, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from "sharp";
import { Readable } from "stream";

const s3 = new S3Client();
const bucketName = process.env.BUCKET_NAME;

// ✅ S3 stream을 buffer로 변환
const streamToBuffer = (stream) =>
  new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data", (chunk) => chunks.push(chunk));
    stream.on("end", () => resolve(Buffer.concat(chunks)));
    stream.on("error", reject);
  });

export const handler = async (event) => {
  try {
    // ✅ 이벤트 유효성 검사
    if (!event.Records || !event.Records[0]) {
      console.error("❌ 잘못된 이벤트 구조:", event);
      return { statusCode: 400, body: "Invalid event structure" };
    }

    // ✅ 환경변수 확인
    if (!bucketName) {
      console.error("❌ 환경변수 BUCKET_NAME이 정의되지 않았습니다.");
      return { statusCode: 500, body: "Missing environment variable BUCKET_NAME" };
    }

    const record = event.Records[0];
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));

    // ✅ uploads/ 경로 필터링
    if (!key.startsWith("uploads/")) {
      console.error("❌ 허용되지 않은 경로:", key);
      return;
    }

    // ✅ 확장자 필터링 (.jpg, .jpeg, .png, .webp)
    if (!/\.(jpg|jpeg|png|webp)$/i.test(key)) {
      console.error("❌ 허용되지 않은 파일 형식:", key);
      return;
    }

    // ✅ 이미지 가져오기
    const getCommand = new GetObjectCommand({
      Bucket: bucketName,
      Key: key,
    });
    const { Body } = await s3.send(getCommand);
    const buffer = await streamToBuffer(Body);

    // ✅ 리사이징 (300px 고정)
    const resizedImage = await sharp(buffer)
      .resize({ width: 300 })
      .toBuffer();

    const outputKey = key.replace("uploads/", "resized/");

    // ✅ MIME 타입 추론
    const contentType = key.endsWith(".png")
      ? "image/png"
      : key.endsWith(".webp")
      ? "image/webp"
      : "image/jpeg";

    // ✅ 리사이징된 이미지 업로드
    const putCommand = new PutObjectCommand({
      Bucket: bucketName,
      Key: outputKey,
      Body: resizedImage,
      ContentType: contentType,
    });

    await s3.send(putCommand);
    console.log("✅ 리사이징 성공:", outputKey);

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Resized and uploaded", key: outputKey }),
    };
  } catch (error) {
    console.error("❌ Lambda 처리 중 오류 발생:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Lambda Error", error: error.message }),
    };
  }
};
