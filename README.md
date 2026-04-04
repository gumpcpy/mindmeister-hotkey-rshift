# MindMeister 右 Shift 修正腳本（Windows）操作說明

本說明適用於在 **Windows** 上使用 **Chrome / Microsoft Edge / Brave** 開啟 **MindMeister**（`mindmeister.com`）時，**右 Shift** 會誤觸「新增媒體（Add Media）」、與 **微軟注音／新注音等輸入法用右 Shift 切換中英文** 衝突的情境。

透過 **AutoHotkey v2** 執行專案內的 `autokey_v7.ahk`，可在 MindMeister 分頁攔截右 Shift 並改送左 Shift，讓輸入法仍能切換中英文，同時降低網頁快捷鍵衝突。

---

## 使用前請確認

| 項目 | 說明 |
|------|------|
| 作業系統 | Windows 10 / 11（建議） |
| 瀏覽器 | Chrome、Microsoft Edge 或 Brave（腳本僅對這三種程式的視窗生效） |
| AutoHotkey 版本 | **必須為 v2**（本腳本第一行為 `#Requires AutoHotkey v2.0`） |
| 分頁標題 | 瀏覽器視窗標題須包含 `MindMeister` 或 `mindmeister`（與網址列是否為 mindmeister 無關；若你的介面標題全無英文，請見文末「疑難排解」） |

---

## 步驟一：安裝 AutoHotkey v2

1. 開啟官方網站：<https://www.autohotkey.com/>
2. 下載 **AutoHotkey v2** 的安裝程式（頁面上請選擇 **v2**，勿與舊版 v1 混淆）。
3. 執行安裝程式，依畫面指示完成安裝（一般使用者維持預設選項即可）。
4. 若電腦上曾安裝 **AutoHotkey v1**，建議確認副檔名 `.ahk` 是由 **v2** 開啟（安裝 v2 時通常會一併設定）。

---

## 步驟二：取得腳本並第一次執行

1. 從本專案（GitHub）下載或複製檔案：  
   `autokeyScript/autokey_v7.ahk`
2. 將 `autokey_v7.ahk` 放在你方便管理的資料夾（例如 `文件\AutoHotkey\`），**請勿**放在會隨意刪除的暫存目錄。
3. 在檔案總管中 **按兩下** `autokey_v7.ahk` 執行。
4. 若成功，工作列右側（系統匣）應會出現 **AutoHotkey 圖示**（綠色 **H**）。此時請在 **MindMeister 分頁** 測試右 Shift 是否不再誤觸媒體、輸入法是否仍可切換中英文。

若要**停止**腳本：在系統匣對 AutoHotkey 圖示按右鍵 → **Exit**（結束）。

---

## 步驟三：開機自動執行

以下使用 Windows 內建的「**啟動**」資料夾，最簡單、也最適合一般使用者。

### 3.1 開啟「啟動」資料夾

1. 按鍵盤 **Windows 鍵 + R** 開啟「執行」。
2. 輸入以下文字後按 **Enter**：  
   ```text
   shell:startup
   ```
3. 會開啟一個名為「啟動」的資料夾（登入 Windows 後會自動執行這裡的捷徑）。

### 3.2 建立腳本捷徑

1. 在檔案總管中找到你的 `autokey_v7.ahk`。
2. 對 `autokey_v7.ahk` 按 **右鍵** → **顯示更多選項**（Windows 11）或直接選 **建立捷徑**。
3. 若建立的是「捷徑」在同一資料夾，請把該 **捷徑** 剪下並 **貼到** 上一小節開啟的「啟動」資料夾。
4. （選用）將捷徑重新命名為易懂的名稱，例如：`MindMeister autokey_v7`。

下次重新開機並登入後，腳本會自動執行。若當天已手動執行過，可能會有兩個 AutoHotkey 在跑——建議只保留一個：在系統匣結束重複的執行個體，或重新開機後只依賴「啟動」資料夾自動執行一次。

---

## 疑難排解

### 腳本好像沒作用

- 確認系統匣是否有 AutoHotkey 圖示；若沒有，請再按兩下 `autokey_v7.ahk` 執行。
- 確認使用的是 **Chrome / Edge / Brave**，且該視窗為**使用中（前景）**。
- 確認分頁的**視窗標題**（瀏覽器最上方）是否包含 `MindMeister` 或 `mindmeister`。若你的介面完全沒有這兩段英文，請用 AutoHotkey 內附的 **Window Spy** 查看實際標題，並依專案說明在腳本中自行增加比對條件（或向專案維護者回報實際標題範例）。

### 想暫時關閉功能

- 在系統匣對 AutoHotkey 圖示按右鍵 → **Exit**，或從工作管理員結束 AutoHotkey 處理程序。

### 與其他 AutoHotkey 腳本同時使用

- 若你已有其他 `.ahk` 常駐，請注意是否有多個腳本搶同一組熱鍵；必要時請合併腳本或調整熱鍵範圍（進階）。

---

## 檔案位置對照

| 檔案 | 說明 |
|------|------|
| `autokeyScript/autokey_v7.ahk` | 主要腳本（請複製到本機固定路徑後使用） |

---

## 免責說明

本腳本為社群輔助用途，不隸屬 MindMeister 或 AutoHotkey 官方。使用與修改請自行承擔風險；建議在重要工作前備份資料，並先於非關鍵環境測試。

若本說明有疏漏或你希望補充截圖版步驟，歡迎在 GitHub 專案提出 Issue 或 Pull Request。
