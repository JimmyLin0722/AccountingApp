# CLAUDE.md

此檔案為 Claude Code (claude.ai/code) 在本專案中運作時的指引文件。

## 對話語言規範

**請一律以繁體中文與我對話。**

## 專案概述

本專案為個人手機記帳 App，支援 iOS 與 Android 雙平台，以 **Flutter** 開發。所有資料皆儲存於裝置本地端，**無後端伺服器、無 API、無任何網路請求**。

## 常用指令

```bash
# 在裝置／模擬器上執行
flutter run

# 建置 Android Release APK
flutter build apk --release

# 建置 iOS Release
flutter build ios --release

# 執行所有測試
flutter test

# 執行單一測試檔案
flutter test test/path/to/widget_test.dart

# 靜態分析
flutter analyze

# 格式化程式碼
dart format .
```

## 系統架構

### 資料層 — SQLite（純本地端）
- 套件：`sqflite` + `path`
- 三張核心資料表：

**`categories`（消費類別表）**
| 欄位名稱 | 資料型態 | 條件約束 |
|---|---|---|
| `category_id` | INTEGER | PK, Auto Increment |
| `category_name` | TEXT | NOT NULL |
| `icon_name` | TEXT | NULL — 對應下方圖示清單的 key |
| `display_order` | INTEGER | DEFAULT 0 |

**`transactions`（記帳明細表）**
| 欄位名稱 | 資料型態 | 條件約束 |
|---|---|---|
| `transaction_id` | INTEGER | PK, Auto Increment |
| `amount` | INTEGER | NOT NULL，正整數，CHECK (amount > 0 AND amount <= 9999999) |
| `category_id` | INTEGER | FK → categories.category_id, NOT NULL |
| `type` | TEXT | NOT NULL，DEFAULT `'expense'`，值域：`'expense'` / `'income'` |
| `note` | TEXT | NULL，備註文字 |
| `transaction_date` | TEXT | NOT NULL，格式：`YYYY-MM-DD` |
| `created_at` | TEXT | DEFAULT CURRENT_TIMESTAMP |

**`monthly_settings`（每月設定表，原 monthly_budgets）**
| 欄位名稱 | 資料型態 | 條件約束 |
|---|---|---|
| `setting_id` | INTEGER | PK, Auto Increment |
| `year_month` | TEXT | NOT NULL, UNIQUE，格式：`YYYY-MM` |
| `income_amount` | INTEGER | NOT NULL DEFAULT 0，本月固定收入（如薪資） |
| `budget_amount` | INTEGER | NOT NULL DEFAULT 0，本月支出預算上限 |

> 此表同時承擔「月收入設定」與「月支出預算」兩個職責，以 `year_month` 為唯一鍵。

SQLite 外鍵約束須在每次連線時明確啟用（`PRAGMA foreign_keys = ON`）。

---

## 功能規格

### A — 收支記帳（type 欄位）
- `type = 'expense'` 為支出（橘色顯示），`type = 'income'` 為收入（藍色顯示）
- **`totalIncome`（總收入）= `monthly_settings.income_amount`（本月固定收入設定）+ 當月個別收入交易加總**
- **`totalExpense`（總支出）= 當月個別支出交易加總**
- 儀表板的**總結餘** = totalIncome − totalExpense
- 總支出、總收入分別獨立加總顯示
- 儀表板「總收入」區塊可直接點擊，快速開啟「設定月收入」對話框

### B — 支出 ↔ 收入切換
- 新增交易頁頂部的「支出 | 收入」Toggle 須真實切換 `type`
- 切換時類別清單不變，但 Toggle 高亮色改變（支出 = 主色橘 `#F4A438`，收入 = 藍 `#4A90D9`）

### C — 儀表板月份切換
- AppBar 的「YYYY年M月 ▼」可點擊，彈出月份選擇器（年份 + 月份滾輪或 Grid）
- 切換後儀表板所有數據（圖表、清單、統計）同步更新至選定月份
- 支援左右滑動手勢切換上下月

### D — 自訂類別管理
- 「新增分類」按鈕開啟類別編輯頁，讓使用者輸入名稱並從圖示清單中選擇圖示
- 支援刪除類別（若有關聯交易則禁止刪除，顯示提示）
- 支援長按拖曳調整顯示順序（更新 `display_order`）

**可選圖示清單（28 個，均為 Flutter Material Icons 內建）**

| key（存入 icon_name）| Icons 常數 | 建議類別 |
|---|---|---|
| `free_breakfast` | `Icons.free_breakfast` | 早餐、咖啡 |
| `lunch_dining` | `Icons.lunch_dining` | 午餐 |
| `dinner_dining` | `Icons.dinner_dining` | 晚餐 |
| `restaurant` | `Icons.restaurant` | 外食、餐廳 |
| `local_cafe` | `Icons.local_cafe` | 飲料、手搖杯 |
| `cake` | `Icons.cake` | 甜點、零食 |
| `directions_bus` | `Icons.directions_bus` | 大眾交通 |
| `directions_car` | `Icons.directions_car` | 開車、停車 |
| `local_taxi` | `Icons.local_taxi` | 計程車、Uber |
| `local_gas_station` | `Icons.local_gas_station` | 加油 |
| `flight` | `Icons.flight` | 機票、旅遊 |
| `shopping_bag` | `Icons.shopping_bag` | 購物 |
| `checkroom` | `Icons.checkroom` | 服飾、衣物 |
| `spa` | `Icons.spa` | 美容、保養 |
| `local_hospital` | `Icons.local_hospital` | 醫療、看診 |
| `fitness_center` | `Icons.fitness_center` | 健身、運動 |
| `sports_esports` | `Icons.sports_esports` | 遊戲、娛樂 |
| `movie` | `Icons.movie` | 電影、影集 |
| `home` | `Icons.home` | 房租、住宿 |
| `electric_bolt` | `Icons.electric_bolt` | 水電、瓦斯 |
| `phone_android` | `Icons.phone_android` | 通訊、電話費 |
| `menu_book` | `Icons.menu_book` | 教育、書籍 |
| `pets` | `Icons.pets` | 寵物 |
| `card_giftcard` | `Icons.card_giftcard` | 禮物、送禮 |
| `savings` | `Icons.savings` | 儲蓄、投資 |
| `payments` | `Icons.payments` | 薪資、收入 |
| `emoji_events` | `Icons.emoji_events` | 獎金、獎勵 |
| `category_outlined` | `Icons.category_outlined` | 其他 |

圖示 key 與 `Icons` 常數的對應須集中維護在 `lib/utils/icon_map.dart`，全專案統一透過此 map 解析，不得散落各 Widget 內硬編碼。

### E — 備註欄位
- 新增交易頁的「輸入備註」欄位須實際寫入 `transactions.note`
- 歷史清單的每筆交易若 `note` 不為空，則在類別名稱下方以灰色小字顯示

### F — 交易編輯
- 歷史清單每筆交易支援點擊進入編輯模式（帶入現有金額、類別、type、note、日期）
- 編輯完成後更新資料庫並即時重繪清單，不新增新紀錄

### G — 預算警示與月設定入口
- 儀表板 AppBar 右側錢包圖示開啟「本月設定」對話框，包含兩個欄位：
  - **本月固定收入**（`income_amount`）：填入薪資等固定收入，立即反映至總收入
  - **本月支出預算**（`budget_amount`）：填入支出上限，達標時顯示警示
- 當月支出達預算的 **80%** 時，儀表板顯示黃色警示 Banner；**超出 100%** 顯示紅色警示 Banner
- 若該月未設定預算（`budget_amount = 0`），則不顯示警示
- 設定儲存於 `monthly_settings` 表（以 `year_month` 為唯一鍵，UPSERT）

---

## 核心業務邏輯

- **金額限制**：正整數，上限 7 位數（9,999,999），鍵盤達上限後拒絕輸入。
- **儲存流程**：驗證（金額 > 0 且已選類別）→ 非同步寫入 DB → 廣播狀態 → 清空金額；**保留**最後選取的類別、type 與日期，方便連續記帳。
- **驗證失敗**：顯示行內提示，保留輸入內容，不寫入 DB。
- **刪除類別**：有關聯交易時禁止刪除（RESTRICT），需先刪除所有關聯交易才能刪除類別。
- **結餘計算**：`總結餘 = SUM(amount WHERE type='income') − SUM(amount WHERE type='expense')`，結餘為負時以紅色顯示。

## 狀態管理

使用 `provider`。Provider 持有當前選定月份（`selectedYearMonth`），月份切換後重新查詢 DB 並 `notifyListeners()`，儀表板所有子元件自動重繪。

## UI 設計規範

- 主色（支出、選取狀態）：`#F4A438`
- 收入色：`#4A90D9`
- OK 按鈕：`#F06060`
- AC / ← 按鍵：`#5BC8C0`
- 數字按鍵：白底深色文字
- 主背景：`#F5F5F5`，卡片：白色，圓角 12px
- 詳細排版參考 `docs/style_0.jpg`；色彩參考 `docs/style_1.jpg`

## Git 工作流程

**每次開始修改前**，必須先同步最新的 main：

```bash
git checkout main
git pull origin main
git checkout claude
git rebase main
```

**修改完成後**，推上 claude 分支：

```bash
git push origin claude
```

推送後提示使用者至 GitHub 建立 PR（`main ← claude`）：
- PR 網址：https://github.com/JimmyLin0722/AccountingApp/compare/main...claude

> **規則**：所有程式碼修改一律提交至 `claude` 分支，絕不直接 commit 到 `main`。

---

## 暫緩功能（Phase 2）

- **H — CSV 匯出**：將所有交易匯出為 CSV，儲存至裝置或分享至 Google Drive / iCloud。
- **I — 跨月趨勢圖**：折線圖呈現過去 6 個月支出走勢。
