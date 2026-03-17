# 📱 Wireless Debugging Setup Guide

## Quick Setup (5 Minutes)

### Method 1: Using Pairing Code (Recommended)

#### Step 1: Enable Wireless Debugging on Phone
1. **Connect phone via USB cable** (one-time only)
2. **On your phone:**
   - Settings → Developer Options
   - Enable "Wireless debugging"
   - Tap on "Wireless debugging"
   - Tap "Pair device with pairing code"
   
3. **You'll see:**
   ```
   Wi-Fi pairing code: 123456
   IP address & Port: 192.168.1.100:37829
   ```

#### Step 2: Pair from Mac Terminal

Open Terminal and run:

```bash
# Replace with YOUR IP and port from phone screen
~/Library/Android/sdk/platform-tools/adb pair 192.168.1.100:37829

# When prompted, enter the 6-digit code from your phone
```

#### Step 3: Connect Wirelessly

After pairing, you'll see another IP address on the main "Wireless debugging" screen (without pairing code). Use that to connect:

```bash
# Replace with the IP from main wireless debugging screen
~/Library/Android/sdk/platform-tools/adb connect 192.168.1.100:12345
```

#### Step 4: Verify Connection

```bash
~/Library/Android/sdk/platform-tools/adb devices
```

You should see:
```
List of devices attached
192.168.1.100:12345    device
```

#### Step 5: Run Your App

```bash
flutter run
```

Flutter will automatically detect your wireless device!

---

## Method 2: Using USB First (Easier)

#### Step 1: Connect via USB
1. Connect phone with USB cable
2. Enable USB debugging
3. Allow USB debugging popup on phone

#### Step 2: Enable TCP/IP Mode

```bash
# Enable wireless debugging on port 5555
~/Library/Android/sdk/platform-tools/adb tcpip 5555
```

#### Step 3: Find Your Phone's IP Address

**On your phone:**
- Settings → About Phone → Status → IP address
- OR Settings → Wi-Fi → Tap your network → IP address

Example: `192.168.1.100`

#### Step 4: Disconnect USB and Connect Wirelessly

```bash
# Disconnect USB cable now

# Connect wirelessly (replace with YOUR phone's IP)
~/Library/Android/sdk/platform-tools/adb connect 192.168.1.100:5555
```

#### Step 5: Verify and Run

```bash
# Check connection
~/Library/Android/sdk/platform-tools/adb devices

# Run your app
flutter run
```

---

## 🔧 Troubleshooting

### Problem: "unable to connect"
**Solution:**
- Make sure phone and Mac are on the SAME Wi-Fi network
- Disable VPN on both devices
- Check firewall settings

### Problem: "device offline"
**Solution:**
```bash
# Restart ADB
~/Library/Android/sdk/platform-tools/adb kill-server
~/Library/Android/sdk/platform-tools/adb start-server

# Try connecting again
~/Library/Android/sdk/platform-tools/adb connect YOUR_IP:5555
```

### Problem: Connection drops
**Solution:**
- Keep phone screen on during development
- Disable battery optimization for ADB
- Stay on same Wi-Fi network

### Problem: Can't find IP address
**Solution:**
- Settings → About Phone → Status
- OR use USB method first, then run:
```bash
~/Library/Android/sdk/platform-tools/adb shell ip addr show wlan0
```

---

## 📝 Quick Commands Reference

```bash
# Check connected devices
~/Library/Android/sdk/platform-tools/adb devices

# Enable wireless mode (USB connected)
~/Library/Android/sdk/platform-tools/adb tcpip 5555

# Connect wirelessly
~/Library/Android/sdk/platform-tools/adb connect IP_ADDRESS:5555

# Disconnect wireless
~/Library/Android/sdk/platform-tools/adb disconnect IP_ADDRESS:5555

# Restart ADB
~/Library/Android/sdk/platform-tools/adb kill-server
~/Library/Android/sdk/platform-tools/adb start-server

# Run Flutter app
flutter run

# Hot reload (when app is running)
# Press 'r' in terminal
```

---

## ✅ Benefits of Wireless Debugging

- 🔌 No USB cable needed
- 🚀 Faster development
- 💻 Freedom to move around
- 🔄 Hot reload still works
- 📱 Multiple devices possible

---

## 🎯 Step-by-Step for Your Phone (Xiaomi/Redmi)

### Initial Setup (Do Once)

1. **Connect USB cable**
2. **Run in Terminal:**
   ```bash
   ~/Library/Android/sdk/platform-tools/adb devices
   ```
   Should show: `18831a897d7a    device`

3. **Enable wireless mode:**
   ```bash
   ~/Library/Android/sdk/platform-tools/adb tcpip 5555
   ```

4. **Find your phone's IP:**
   - Settings → Wi-Fi → Tap your network
   - Note the IP address (e.g., 192.168.1.100)

5. **Disconnect USB cable**

6. **Connect wirelessly:**
   ```bash
   ~/Library/Android/sdk/platform-tools/adb connect 192.168.1.100:5555
   ```

7. **Run your app:**
   ```bash
   flutter run
   ```

### Daily Use (After Setup)

Just run:
```bash
~/Library/Android/sdk/platform-tools/adb connect YOUR_IP:5555
flutter run
```

---

## 🔐 Security Note

Wireless debugging is less secure than USB. Only use on trusted networks. Disable when not needed.

---

## 💡 Pro Tips

1. **Save your IP:** Create an alias in terminal
   ```bash
   alias connect-phone="~/Library/Android/sdk/platform-tools/adb connect 192.168.1.100:5555"
   ```

2. **Keep phone awake:** Settings → Developer Options → Stay awake (when charging)

3. **Static IP:** Set static IP for your phone in router settings

4. **Multiple devices:** You can connect multiple phones wirelessly!

---

## 📞 Need Help?

If you're stuck, just:
1. Connect USB cable
2. Run `flutter run`
3. Works every time! 😊

Wireless is convenient but USB is always reliable.
