import React, { useState, useEffect } from "react";

function App() {
  const [file, setFile] = useState(null);
  const [apiUrl, setApiUrl] = useState("");
  const [message, setMessage] = useState("");
  const [uploadedUrl, setUploadedUrl] = useState("");

  // alb-config.json에서 API Gateway 주소 불러오기
  useEffect(() => {
    fetch("/alb-config.json")
      .then((res) => res.json())
      .then((config) => {
        if (config.apiUrl) {
          setApiUrl(config.apiUrl);
        } else {
          throw new Error("alb-config.json에 'apiUrl' 키가 없습니다.");
        }
      })
      .catch((err) => {
        console.error("❌ alb-config.json 로딩 실패:", err);
        setMessage("API 주소를 불러오지 못했습니다.");
      });
  }, []);

  const handleFileChange = (e) => {
    const selected = e.target.files[0];
    setFile(selected);
    setMessage("");
    setUploadedUrl("");
  };

  const uploadImage = async () => {
    if (!file || !apiUrl) return;

    try {
      // 1️⃣ Presigned URL 요청 (GET + Query String 방식)
      const queryParams = new URLSearchParams({
        filename: file.name,
        mimetype: file.type,
        size: file.size,
      }).toString();

      const res = await fetch(`${apiUrl}/presign?${queryParams}`, {
        method: "GET",
      });

      if (!res.ok) throw new Error("Presigned URL 요청 실패");

      const { url } = await res.json();

      // 2️⃣ Presigned URL로 PUT 업로드
      const uploadRes = await fetch(url, {
        method: "PUT",
        headers: { "Content-Type": file.type },
        body: file,
      });

      if (!uploadRes.ok) throw new Error("S3 업로드 실패");

      setMessage("✅ 업로드 완료!");
      const s3Path = url.split("?")[0]; // query string 제거
      setUploadedUrl(s3Path);
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
      <button onClick={uploadImage} disabled={!file || !apiUrl}>
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
