import React, { useState, useEffect } from "react";

function App() {
  const [file, setFile] = useState(null);
  const [apiUrl, setApiUrl] = useState("");
  const [cdnUrl, setCdnUrl] = useState(""); // ✅ 추가: CloudFront 도메인
  const [message, setMessage] = useState("");
  const [uploadedUrl, setUploadedUrl] = useState("");

  // alb-config.json에서 API Gateway 주소와 CloudFront 주소 불러오기
  useEffect(() => {
    fetch("/alb-config.json")
      .then((res) => res.json())
      .then((config) => {
        if (!config.apiUrl || !config.cdnUrl) {
          throw new Error("alb-config.json에 'apiUrl' 또는 'cdnUrl' 키가 없습니다.");
        }
        setApiUrl(config.apiUrl);
        setCdnUrl(config.cdnUrl); // ✅ cdnUrl 저장
      })
      .catch((err) => {
        console.error("❌ alb-config.json 로딩 실패:", err);
        setMessage("API 설정 정보를 불러오지 못했습니다.");
      });
  }, []);

  const handleFileChange = (e) => {
    const selected = e.target.files[0];
    setFile(selected);
    setMessage("");
    setUploadedUrl("");
  };

  const uploadImage = async () => {
    if (!file || !apiUrl || !cdnUrl) return;

    try {
      // 1️⃣ Presigned URL 요청
      const res = await fetch(`${apiUrl}/presign`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          filename: file.name,
          mimetype: file.type,
          size: file.size
        })
      });

      if (!res.ok) throw new Error("Presigned URL 요청 실패");

      const { url } = await res.json();

      // 2️⃣ S3에 이미지 PUT 업로드
      const uploadRes = await fetch(url, {
        method: "PUT",
        headers: { "Content-Type": file.type },
        body: file,
      });

      if (!uploadRes.ok) throw new Error("S3 업로드 실패");

      // ✅ CloudFront URL로 변환
      const key = new URL(url).pathname; // "/uploads/파일.jpg"
      const cloudfrontImageUrl = `${cdnUrl}${key}`; // "https://CloudFront도메인/uploads/파일.jpg"

      setMessage("✅ 업로드 완료!");
      setUploadedUrl(cloudfrontImageUrl);
    } catch (err) {
      console.error("❌ 업로드 실패:", err);
      setMessage("❌ 업로드 실패: " + err.message);
    }
  };

  return (
    <div style={{ padding: "2rem", fontFamily: "Arial" }}>
      <h2>📷 이미지 업로드</h2>
      <input type="file" accept="image/*" onChange={handleFileChange} />
      <br /><br />
      <button onClick={uploadImage} disabled={!file || !apiUrl || !cdnUrl}>
        Presigned URL로 업로드
      </button>
      <p>{message}</p>
      {uploadedUrl && (
        <div>
          <h4>✅ 업로드된 이미지</h4>
          <img src={uploadedUrl} alt="uploaded" width="300" />
        </div>
      )}
    </div>
  );
}

export default App;
