# MindMeister 右 Shift 快捷鍵需求

## 背景

在 MindMeister 中，右 Shift 會觸發 **Add Media**，需要攔截此行為，同時保留微軟中文輸入法的相關功能。

## 功能需求

### 已實現（v7）

- **防止 Add Media**：攔截右 Shift，不讓 MindMeister 收到
- **切換中英文**：右 Shift 單獨按放 → 微軟輸入法切換中英文

### v8 新增

1. **右 Shift + 字母 → 大寫**：按住右 Shift 再按英文字母，輸出大寫
2. **右 Shift + 空格 → 全形/半形切換**：按住右 Shift 再按空格，切換全形與半形

---

## v7 → v8 技術差異

### v7 做法

```
RShift 按下 → 立刻送完整的 {LShift}（按＋放）→ KeyWait 等放開
```

**問題**：RShift 持續按住期間，系統不認為有任何 Shift 被按著，所以無法打大寫，也無法觸發 Shift+Space。

### v8 做法

```
RShift ↓ → SendInput("{LShift Down}")   ← 系統開始看到 LShift 被按住
RShift ↑ → SendInput("{LShift Up}")     ← 系統看到 LShift 放開
```

整段期間 LShift 都是持續按住的狀態，自然支援所有 Shift 組合鍵。

---

## 功能對照表

| 操作 | 系統看到 | 結果 |
|------|---------|------|
| 右 Shift 單獨按放 | LShift 一按一放，中間無其他鍵 | 微軟輸入法切換中英文 |
| 右 Shift 按住 + 字母 | LShift 持續按住 + 字母 | 打出大寫英文 |
| 右 Shift + 空格 | LShift + Space | 切換全形/半形 |

> MindMeister 全程收不到右 Shift，所以不會觸發 Add Media。

---

## 補充說明

### 安全措施

新增 `g_rshiftRemapped` 旗標和第二個 `#HotIf` 區塊，處理「按住右 Shift 期間焦點從 MindMeister 切走」的邊界情況，避免 LShift 卡住。

### 備援模式

舊備援模式（`USE_SEND_LSHIFT_FOR_IME := false`）完整保留，行為與 v7 相同。大寫和全半形切換功能僅在主模式下生效。
