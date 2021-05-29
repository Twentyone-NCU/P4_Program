# P4 Backup Line with Controller

## 簡介

使用工具介紹

1. VM：[金門大學_柯志亨](https://webhd.ncyu.edu.tw/share.cgi?ssid=0CY94tl)  **password﹕user**
2. ![拓譜](https://drive.google.com/file/d/1DSLmtNt9zbW81q4qUaNMthHawV36IWVR/view?usp=sharing)


##實驗步驟
1. 下載此資料夾
```shell
git clone https://github.com/Twentyone-NCU/P4_Program.git
```
2. 開啟 terminal 並`cd`至此資料夾下
```shell
cd P4_Program/Comtroller/
```
3. 執行 P4
```shell
sudo p4run
```
4. 開啟 `xterm`host 1和host 2
```shell
xterm h1 h2
```
5. 開啟新的 terminal 啟動 Controller
```shell
cd P4_Program/Comtroller/
sudo python controller.py
```
6. 測試 flow，先執行 h2 再執行 h1
>h1 xterm
```shell
iperf -c 10.0.6.2 -u -b 10M -t 1
```
>h2 xterm
```shell
iperf -s -i 1 -u
```
7. 透過`simple_switch_CLI`進入 s3 將 table 清除
```shell
sudo simple_switch_CLI --thrift-port 9092
table_clear ipv4_lpm
table_clear forward
```
8. h1 傳送資料
```shell
iperf -c 10.0.6.2 -u -b 10M -t 1
```

9. 結果


```graph LR 
h1 --> s1 --> s7 --> s4 --> s6 --> h2
```




###### tags: `P4` `SDN`
