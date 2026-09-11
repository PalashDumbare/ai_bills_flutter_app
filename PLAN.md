# AI Bills Flutter App — Plan

## Core Concept
A bill/receipt scanner + AI assistant app:
1. **Upload** — user takes a photo or picks a PDF of a bill or appliance invoice
2. **Auto-extract** — backend OCRs and parses it (amounts, dates, warranty, provider, etc.)
3. **Structured view** — parsed data shown as cards (bills, appliances)
4. **Chat with docs** — user asks questions like "When does my fridge warranty expire?" and gets AI-powered answers

---

## Tech Stack

| Layer | Choice |
|-------|--------|
| State Management | **Riverpod** |
| Navigation | **GoRouter** |
| HTTP Client | **Dio** |
| Local Storage | **Hive** |
| Image Picker | **image_picker** + **file_picker** |
| UI Kit | Material 3 with custom theme |

---

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── api.dart
│   └── theme.dart
├── models/
│   ├── document.dart
│   ├── appliance.dart
│   └── bill.dart
├── providers/
│   ├── documents_provider.dart
│   ├── chat_provider.dart
│   └── auth_provider.dart
├── services/
│   ├── api_service.dart
│   └── local_storage.dart
├── screens/
│   ├── home/
│   ├── documents/
│   ├── chat/
│   └── settings/
├── widgets/
│   ├── cards/
│   ├── common/
│   └── chat/
└── utils/
    ├── date_formatter.dart
    └── currency_formatter.dart
```

---

## Screens & Navigation

```
Bottom Nav (3 tabs):
┌─────────┬──────────┬──────────┐
│  Home   │ Documents│   Chat   │
└─────────┴──────────┴──────────┘
+ Upload (full-screen push)
+ Document Detail (full-screen push)
+ Settings (full-screen push)
```

### Home Screen
Dashboard with stats cards (total docs, total tracked) + recent documents list + "Scan Bill" FAB

### Upload Screen
Camera / Gallery / PDF picker → preview → upload & process pipeline

### Document List
All uploaded documents, filterable by type

### Document Detail
Structured data view (bill or appliance card with all parsed fields)

### Chat Screen
AI Q&A interface, ask questions about indexed documents, shows answer + source citations

### Settings
Profile, dark mode toggle, language, app version

---

## Color Palette (Material 3)

```
Primary:     #2563EB (Blue)
Secondary:   #7C3AED (Purple)
Success:     #10B981 (Green — warranty OK)
Warning:     #F59E0B (Amber — due soon)
Error:       #EF4444 (Red — overdue)
Background:  #F8FAFC (Light) / #0F172A (Dark)
```

---

## API Integration Flow

```
Upload:  image_picker/file_picker → POST /documents/upload → POST /extract → POST /structure → POST /index
Chat:    user question → POST /chat (with optional document_id) → display answer + sources
```

---

## Key Features

| Feature | Description |
|---------|-------------|
| Camera/Gallery | Pick image, preview before upload |
| PDF Support | Pick PDF file, preview with icon |
| Auto-process | Upload → Extract → Structure → Index in one flow |
| Document Cards | Color-coded by type (bill=blue, appliance=purple) |
| Warranty Alerts | Warning badge when warranty < 3 months |
| Bill Dashboard | Total spent, upcoming dues, category breakdown |
| Chat with Docs | Natural language Q&A with source citations |
| Dark Mode | Full dark theme support |
| Responsive | Mobile, tablet, and web layouts |

---

## Implementation Order

1. **Project setup** — theme, navigation shell, folder structure
2. **Upload screen** — camera/gallery/PDF picker, preview, backend integration
3. **Document list + detail** — fetch/display structured data from backend
4. **Chat screen** — AI Q&A interface
5. **Dashboard/home** — stats, recent docs, category breakdown
6. **Polish** — dark mode finalization, web responsive, animations

---

## Known Issues

- Web upload fails with "Multipart file is only supported where dart.io is available"
- `Dio MultipartFile.fromFile()` uses `dart:io` which doesn't exist on web
- Need to use `MultipartFile.fromBytes()` with platform detection for web uploads
