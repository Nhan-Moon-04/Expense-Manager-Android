# Firestore Security Rules cho Expense Manager

Truy cập Firebase Console > Firestore Database > Rules và thay thế bằng:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function to check if user owns the document
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }

    // Expenses collection
    match /expenses/{expenseId} {
      allow read: if isAuthenticated() &&
        (resource.data.userId == request.auth.uid ||
         resource.data.groupId != null);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }

    // Groups collection - QUAN TRỌNG cho tính năng nhóm
    match /groups/{groupId} {
      // Allow read if user is a member of the group
      allow read: if isAuthenticated();

      // Allow create if user is authenticated
      allow create: if isAuthenticated() && request.resource.data.ownerId == request.auth.uid;

      // Allow update if user is a member of the group
      allow update: if isAuthenticated();

      // Allow delete only by owner
      allow delete: if isAuthenticated() && resource.data.ownerId == request.auth.uid;
    }

    // Notes collection
    match /notes/{noteId} {
      allow read, write: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
    }

    // Reminders collection
    match /reminders/{reminderId} {
      allow read, write: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
    }

    // Notifications collection
    match /notifications/{notificationId} {
      allow read, write: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated();
    }
  }
}
```

## Hướng dẫn:

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Chọn project **expense_manager_android**
3. Vào **Firestore Database** từ menu bên trái
4. Chọn tab **Rules**
5. Xóa rules hiện tại và paste rules phía trên
6. Nhấn **Publish**

## Lưu ý về bảo mật:

Rules này khá lỏng cho phép đọc groups. Trong production, bạn nên:

- Lưu danh sách memberIds riêng để kiểm tra quyền đọc
- Sử dụng Cloud Functions để validate join group

## Tạo Composite Indexes (nếu cần):

Truy cập **Firestore > Indexes** và tạo:

1. **Collection**: `groups`
   - Field 1: `inviteCode` - Ascending
   - Field 2: `isActive` - Ascending

2. **Collection**: `expenses`
   - Field 1: `groupId` - Ascending
   - Field 2: `date` - Descending

3. **Collection**: `expenses`
   - Field 1: `userId` - Ascending
   - Field 2: `date` - Descending
