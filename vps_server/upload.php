<?php
/**
 * Expense Manager - VPS Image Upload API Handler
 * Endpoint: POST http://nthiennhan.ddns.net:90/api/upload.php
 * Lưu trữ ảnh vào /var/www/html/uploads/receipts/ hoặc /var/www/html/uploads/{folder}/
 */

// Enable CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "success" => false,
        "message" => "Method not allowed. Use POST."
    ]);
    exit;
}

// Check if file was uploaded
if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    $errorCode = isset($_FILES['file']) ? $_FILES['file']['error'] : 'No file sent';
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Không tìm thấy file ảnh hoặc lỗi upload.",
        "error_code" => $errorCode
    ]);
    exit;
}

$file = $_FILES['file'];
$folder = isset($_POST['folder']) ? trim($_POST['folder']) : 'receipts';

// Sanitize folder name
$folder = preg_replace('/[^a-zA-Z0-9_\-\/]/', '', $folder);
if (empty($folder)) {
    $folder = 'receipts';
}

// Target directory
$baseUploadDir = '/var/www/html/uploads';
$targetDir = $baseUploadDir . '/' . $folder;

// Create target directory if it doesn't exist
if (!is_dir($targetDir)) {
    if (!mkdir($targetDir, 0755, true)) {
        http_response_code(500);
        echo json_encode([
            "success" => false,
            "message" => "Không thể tạo thư mục lưu trữ trên server VPS."
        ]);
        exit;
    }
}

// Validate file type
$allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
$fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

if (!in_array($fileExtension, $allowedExtensions)) {
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Định dạng file không hợp lệ. Chỉ chấp nhận: " . implode(', ', $allowedExtensions)
    ]);
    exit;
}

// Generate unique filename with timestamp
$uniqueId = bin2hex(random_bytes(8));
$newFileName = 'img_' . date('Ymd_His') . '_' . $uniqueId . '.' . $fileExtension;
$targetFilePath = $targetDir . '/' . $newFileName;

// Move uploaded file to target directory
if (move_uploaded_file($file['tmp_name'], $targetFilePath)) {
    // Determine public URL
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off' || $_SERVER['SERVER_PORT'] == 443) ? "https://" : "http://";
    $host = $_SERVER['HTTP_HOST']; // includes port if non-standard (e.g. nthiennhan.ddns.net:90)
    
    // Relative URL path
    $relativePath = '/uploads/' . $folder . '/' . $newFileName;
    $publicUrl = $protocol . $host . $relativePath;

    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Upload ảnh thành công",
        "url" => $publicUrl,
        "relative_path" => $relativePath,
        "file_name" => $newFileName,
        "size" => filesize($targetFilePath),
        "uploaded_at" => date('c')
    ], JSON_UNESCAPED_SLASHES);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Lỗi lưu file vào server VPS. Vui lòng kiểm tra quyền thư mục (chown www-data)."
    ]);
}
