**🌐 Language:** English | [Español](README.es.md) | [正體中文](README.zh-TW.md)

### Duolingo PRO

This is a simple and handy tool that allows you to quickly redeem Duolingo resources:

- XP (Experience Points)
- Gems
- Duolingo Super 3-Day Trial
- Streak Freezes
- Heart Refill
- XP Boost

#### How to Use

1. Download the [APK file](https://raw.githubusercontent.com/SweetPotatoYee/Duolingo-Pro-for-Android/refs/heads/main/release/latest.apk)
2. Install and open the app  
3. Tap the avatar icon in the top-right corner and enter your User ID  
4. Choose the function you want  
5. Enter the amount and send the request  
6. Wait for the process to finish — the resources will be added!

#### How to Get Your User ID

1. Go to [Duolingo](https://duolingo.com)  
2. In the address bar, type `j` and paste the following code:  

```
javascript:(function(){try{const token=document.cookie.split(';').find(c=>c.includes('jwt_token')).split('=')[1];const el=document.createElement('textarea');el.value=token;document.body.appendChild(el);el.select();document.execCommand('copy');document.body.removeChild(el);alert('User ID copied: '+token);}catch(e){alert('Login info not found');}})();
```

3. Press Enter (not search) — your User ID will be copied automatically  
4. Paste it into the app

#### Notes

- Make sure you are logged in to Duolingo or the ID won’t be found  
- If the request fails, try again in a few seconds  
- For educational purposes only. Use at your own risk.

Feel free to report bugs or suggestions.
