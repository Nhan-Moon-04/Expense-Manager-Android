# Bank Rules JSON Format

This document describes the correct format for the bank notification rules that should be uploaded to:
`https://raw.githubusercontent.com/Nhan-Moon-04/Rules-Json/refs/heads/main/rule_bank.json`

## Complete JSON Structure

```json
{
  "version": 1,
  "lastUpdated": "2026-02-17",
  "banks": [
    {
      "id": "momo",
      "name": "MoMo",
      "packageName": "com.mservice.momotransfer",
      "enabled": true,
      "titleFilter": null,
      "rules": [
        {
          "name": "Chuyển tiền / Thanh toán",
          "type": "expense",
          "titleMatch": null,
          "bodyMatch": "(chuyển|chuyen|thanh toán|thanh toan|chi|trừ|tru|payment|đã thanh toán|da thanh toan|đã chuyển|da chuyen)",
          "bodyExclude": "(khuyến mãi|thất bại|không thành công|thưởng|voucher|ưu đãi|giảm giá)",
          "amountPattern": "([\\d.,]+)\\s*(đ|₫|vnd|vnđ|VND|VNĐ)",
          "descriptionPattern": null
        },
        {
          "name": "Nhận tiền",
          "type": "income",
          "titleMatch": null,
          "bodyMatch": "(nhận|nhan|cộng|cong|được|duoc|receive|hoàn tiền|hoan tien|refund)",
          "bodyExclude": "(khuyến mãi|thất bại|không thành công|thưởng|voucher|ưu đãi|giảm giá)",
          "amountPattern": "([\\d.,]+)\\s*(đ|₫|vnd|vnđ|VND|VNĐ)",
          "descriptionPattern": null
        }
      ]
    },
    {
      "id": "vcb",
      "name": "Vietcombank",
      "packageName": "com.VCB",
      "enabled": true,
      "titleFilter": "(biến động|bien dong|thay đổi số dư|thay doi so du|số dư|so du|giao dịch|giao dich|GD|TK)",
      "rules": [
        {
          "name": "Biến động số dư (có dấu +/-)",
          "type": "auto",
          "titleMatch": null,
          "bodyMatch": null,
          "bodyExclude": null,
          "amountPattern": "([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)",
          "descriptionPattern": "(?:ND|Noi dung|N\\.D|Nội dung|Noi dung GD|Nội dung GD|Noi dung giao dich|Nội dung giao dịch)[:\\s]+(.+?)(?:\\.|;|\\n|$)"
        }
      ]
    },
    {
      "id": "mbbank",
      "name": "MB Bank",
      "packageName": "com.mbmobile",
      "enabled": true,
      "titleFilter": "(biến động|bien dong|thay đổi số dư|thay doi so du|số dư|so du|giao dịch|giao dich|GD|TK)",
      "rules": [
        {
          "name": "Biến động số dư",
          "type": "auto",
          "titleMatch": null,
          "bodyMatch": null,
          "bodyExclude": null,
          "amountPattern": "([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)",
          "descriptionPattern": "(?:ND|Noi dung|N\\.D|Nội dung|Noi dung GD|Nội dung GD|Noi dung giao dich|Nội dung giao dịch)[:\\s]+(.+?)(?:\\.|;|\\n|$)"
        }
      ]
    },
    {
      "id": "techcombank",
      "name": "Techcombank",
      "packageName": "vn.com.techcombank.bb.app",
      "enabled": true,
      "titleFilter": "(biến động|bien dong|thay đổi số dư|thay doi so du|số dư|so du|giao dịch|giao dich|GD|TK)",
      "rules": [
        {
          "name": "Biến động số dư",
          "type": "auto",
          "titleMatch": null,
          "bodyMatch": null,
          "bodyExclude": null,
          "amountPattern": "([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)",
          "descriptionPattern": "(?:ND|Noi dung|N\\.D|Nội dung|Noi dung GD|Nội dung GD|Noi dung giao dich|Nội dung giao dịch)[:\\s]+(.+?)(?:\\.|;|\\n|$)"
        }
      ]
    },
    {
      "id": "bidv",
      "name": "BIDV",
      "packageName": "com.vnpay.bidv",
      "enabled": true,
      "titleFilter": "(biến động|bien dong|thay đổi số dư|thay doi so du|số dư|so du|giao dịch|giao dich|GD|TK)",
      "rules": [
        {
          "name": "Biến động số dư",
          "type": "auto",
          "titleMatch": null,
          "bodyMatch": null,
          "bodyExclude": null,
          "amountPattern": "([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)",
          "descriptionPattern": "(?:ND|Noi dung|N\\.D|Nội dung|Noi dung GD|Nội dung GD|Noi dung giao dich|Nội dung giao dịch|Lý do|Ly do)[:\\s]+(.+?)(?:\\.|;|\\n|$)"
        }
      ]
    },
    {
      "id": "tpbank",
      "name": "TPBank",
      "packageName": "com.tpb.mb.gprsandroid",
      "enabled": true,
      "titleFilter": "(biến động|bien dong|thay đổi số dư|thay doi so du|số dư|so du|giao dịch|giao dich|GD|TK)",
      "rules": [
        {
          "name": "Biến động số dư",
          "type": "auto",
          "titleMatch": null,
          "bodyMatch": null,
          "bodyExclude": null,
          "amountPattern": "([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)",
          "descriptionPattern": "(?:ND|Noi dung|N\\.D|Nội dung|Noi dung GD|Nội dung GD|Noi dung giao dich|Nội dung giao dịch)[:\\s]+(.+?)(?:\\.|;|\\n|$)"
        }
      ]
    },
    {
      "id": "vietinbank",
      "name": "VietinBank",
      "packageName": "com.vietinbank.ipay",
      "enabled": true,
      "titleFilter": "(biến động|bien dong|Biến động|iPay|IPay|ipay)",
      "rules": [
        {
          "name": "Biến động số dư iPay",
          "type": "auto",
          "titleMatch": null,
          "bodyMatch": "(Giao d[iị]ch|Ph[áa]t sinh|Phat sinh|PS)",
          "bodyExclude": null,
          "amountPattern": "(?:Giao d[iị]ch|Ph[áa]t sinh|Phat sinh|PS)[:\\s]*([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)",
          "descriptionPattern": "N[oộ]i dung[:\\s]+(.+?)(?:\\.|;|\\n|$)"
        }
      ]
    },
    {
      "id": "acb",
      "name": "ACB",
      "packageName": "mobile.acb.com.vn",
      "enabled": true,
      "titleFilter": "(biến động|bien dong|thay đổi số dư|thay doi so du|số dư|so du|giao dịch|giao dich|GD|TK)",
      "rules": [
        {
          "name": "Biến động số dư",
          "type": "auto",
          "titleMatch": null,
          "bodyMatch": null,
          "bodyExclude": null,
          "amountPattern": "([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)",
          "descriptionPattern": "(?:ND|Noi dung|N\\.D|Nội dung|Noi dung GD|Nội dung GD|Noi dung giao dich|Nội dung giao dịch)[:\\s]+(.+?)(?:\\.|;|\\n|$)"
        }
      ]
    },
    {
      "id": "sacombank",
      "name": "Sacombank",
      "packageName": "src.com.sacombank",
      "enabled": true,
      "titleFilter": "(biến động|bien dong|thay đổi số dư|thay doi so du|số dư|so du|giao dịch|giao dich|GD|TK)",
      "rules": [
        {
          "name": "Biến động số dư",
          "type": "auto",
          "titleMatch": null,
          "bodyMatch": null,
          "bodyExclude": null,
          "amountPattern": "([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)",
          "descriptionPattern": "(?:ND|Noi dung|N\\.D|Nội dung|Noi dung GD|Nội dung GD|Noi dung giao dich|Nội dung giao dịch)[:\\s]+(.+?)(?:\\.|;|\\n|$)"
        }
      ]
    },
    {
      "id": "agribank",
      "name": "Agribank",
      "packageName": "com.vnpay.Agribank3g",
      "enabled": true,
      "titleFilter": "(biến động|bien dong|thay đổi số dư|thay doi so du|số dư|so du|giao dịch|giao dich|GD|TK)",
      "rules": [
        {
          "name": "Biến động số dư",
          "type": "auto",
          "titleMatch": null,
          "bodyMatch": null,
          "bodyExclude": null,
          "amountPattern": "([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)",
          "descriptionPattern": "(?:ND|Noi dung|N\\.D|Nội dung|Noi dung GD|Nội dung GD|Noi dung giao dich|Nội dung giao dịch)[:\\s]+(.+?)(?:\\.|;|\\n|$)"
        }
      ]
    }
  ],
  "globalIgnorePatterns": [
    "OTP",
    "mã xác thực",
    "ma xac thuc",
    "mã giao dịch",
    "xác nhận",
    "đăng nhập",
    "dang nhap",
    "mật khẩu",
    "mat khau",
    "cập nhật",
    "cap nhat",
    "nâng cấp",
    "khuyến mãi đặc biệt",
    "tải app",
    "download",
    "quảng cáo"
  ]
}
```

## Key Features

### 1. Transaction Type Detection

- **`type: "auto"`** - Automatically detects income/expense from +/- sign in the notification
  - `-` sign = expense (money out)
  - `+` sign = income (money in)
- **`type: "expense"`** - Always treat as expense
- **`type: "income"`** - Always treat as income

### 2. Amount Extraction Only

- The system **only extracts the transaction amount** (income or expense)
- **Does NOT track account balance** - balance information is ignored
- Focuses on cash flow: money in vs money out

### 3. Pattern Matching

#### Amount Pattern (auto type with +/- detection)

```regex
([-+])([\\d.,]+)\\s*(VND|VNĐ|vnd|vnđ|đ|₫)
```

- Group 1: Sign (+ or -)
- Group 2: Amount (numbers with dots/commas)
- Group 3: Currency symbol

#### Amount Pattern (fixed type)

```regex
([\\d.,]+)\\s*(đ|₫|vnd|vnđ|VND|VNĐ)
```

- Group 1: Amount only
- Type is predetermined (expense or income)

### 4. Description Extraction

```regex
(?:ND|Noi dung|N\\.D|Nội dung|Noi dung GD|Nội dung GD)[:\\s]+(.+?)(?:\\.|;|\\n|$)
```

Captures the transaction description/note from the notification.

### 5. Global Ignore Patterns

Notifications containing these keywords are completely ignored:

- OTP codes
- Login confirmations
- Password resets
- Promotional messages
- App download prompts
- Advertisements

## Package Names (Android)

| Bank        | Package Name                |
| ----------- | --------------------------- |
| MoMo        | `com.mservice.momotransfer` |
| Vietcombank | `com.VCB`                   |
| MB Bank     | `com.mbmobile`              |
| Techcombank | `vn.com.techcombank.bb.app` |
| BIDV        | `com.vnpay.bidv`            |
| TPBank      | `com.tpb.mb.gprsandroid`    |
| VietinBank  | `com.vietinbank.ipay`       |
| ACB         | `mobile.acb.com.vn`         |
| Sacombank   | `src.com.sacombank`         |
| Agribank    | `com.vnpay.Agribank3g`      |

## How It Works

1. App receives notification from banking app
2. Checks if package name matches any bank in the rules
3. Checks if notification should be ignored (global patterns)
4. If bank has `titleFilter`, checks if title matches (optional filter)
5. Tries each rule in order until one matches
6. Extracts amount using regex pattern
7. Determines transaction type:
   - For `auto` type: uses +/- sign from notification
   - For fixed type: uses predefined type
8. Extracts description if pattern is provided
9. Creates transaction record with:
   - Amount (income or expense)
   - Description
   - Bank name
   - Timestamp

## Notes

- Update `lastUpdated` field when making changes
- Increase `version` number for major changes
- Test regex patterns carefully - they use Java regex syntax
- Use `\\` for escaping in JSON strings
- All pattern matching is **case-insensitive**
- Balance information from notifications is **ignored** - only transaction amounts matter
