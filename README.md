# Multi_Queue
## 情境:
* 於mininet自行架設的拓譜環境後，頂定 switch 來源位址的 priority 設置
## 目的: 
* 進行更有效的 QoS 配置處理


# 步驟解析:
1. 開啟 [ip_forward.p4](https://github.com/Twentyone-NCU/Multi_Queue/blob/main/ip_forward.p4)
* 設定 metadata 用於之後 priority 條件用
* 於 control egress 定義 register 存取 qdepth
* 於 contorl ingress 定義 priority 優先等於順序

2. 開啟 [monitor.sh](https://github.com/Twentyone-NCU/Multi_Queue/blob/main/monitor_qlens3h3s4.sh) 執行檔
* 寫下需存取指定 switch 指令，並將訊息寫成新檔案

3. 執行 p4 程式
* ffplay 開啟路線流量
  >開兩個h2終端機 (接收端)
  >>第一個h2終端機 (接收udp)
  >>```shell
  >>iperf -s -i 1 -u
  >>```
  >>第二個h2終端機 (播放影片)
  >>```shell
  >>ffplay -i udp://10.0.6.2:1234
  >>```
  
  >h1終端機 (傳送影片  1.mp4)
  >```shell
  >ffmpeg -stream_loop -1 -re -i 1.mp4 -c copy -f mpegts udp://10.0.6.2:1234
  >```
  
* 開啟另一邊終端傳送，在與上述影片會經過同 switch 的條件下，進行 burst traffic 動作
  >h3終端機 (接收端)
  >```shell
  >iperf -s -i 1 -u
  >```
  
  >h5終端機 (傳送端)
  >```shell
  >iperf -c 10.0.2.5 -u -b 10M -t 100
  >```
  
* 查看影片是否維持一樣品質，若品質維持一樣則代表成功。

4. 將 sh 寫出的檔案進行資料篩選動作
```shell
cat <text_name> | tr "Be_replaced_words" "Replace_word" | awk '{print $<wanted_elements_column>, $<wanted_elements_column2>, ...}' > <NewTextName>
```

5. 使用 gnuplot 將蒐集到的數據會出來
```shell
gnuplot
gnuplot> plot "NewTextName" w lp, "NewTextName2" w lp
```

# Reference

## Chih-Heng Ke柯志亨老師網站所提供:
* [H.264 RTP video streaming over P4 networks](http://csie.nqu.edu.tw/smallko/sdn/p4_rtp_h264.htm)
* [原始程式碼](https://www.dropbox.com/sh/9qzkarvkwehgn9q/AACd0tdvpSJj0qu9Y1EjD3rHa/p4-utils-example/p4_queue_video?dl=0&subfolder_nav_tracking=1)
## Youtube Source:
### Channel: Chih-Heng Ke柯志亨
### mininet-p4 4:
* [gnuplot 的學習](https://youtu.be/zzSksWCpu5M)
### mininet-p4 8:
* [queue 資訊的取得](https://youtu.be/lRn9A-im0ws)
### mininet-p4 18:
* [Multi-Queue 的建置](https://youtu.be/4pFAD9R9M0k)
