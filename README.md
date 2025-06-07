# WSCHD
WSCHDの基板です。
<p>
zwenergy氏の作成した「swancolorHD」を基に再設計しました。<br>
swancolorHD<br>
https://github.com/zwenergy/swancolorHD
</p>
<p>
  <img src="https://raw.githubusercontent.com/plusmmm/WSCHD/main/Rev1.5.0.png" width="30%">
</p>
<p>
  HDMIケーブルの抜き差し無しで起動できるようになりました。
</p>

<h3>PCB BOM</h3>
<p>
  swancolorHDからパーツに変更があります。
</p>
<table>
  <tr>
    <th>番号</th>
    <th>パーツ</th>
    <th>LCSC Part #</th>
  </tr>
  <tr>
    <th>R1</th>
    <td>10kΩ 抵抗</td>
    <td>C17414</td>
  </tr>
  <tr>
    <th>U5</th>
    <td>レギュレーター</td>
    <td>C474401</td>
  </tr>
  <tr>
    <th>C1</th>
    <td>キャパシタ 1206 10uF</td>
    <td>C9807</td>
  </tr>
  <tr>
    <th>C2-C4</th>
    <td>キャパシタ 1206 100uF</td>
    <td>C7432784</td>
  </tr>
  <tr>
    <th>Q13</th>
    <td>Pチャンネル MOSFET</td>
    <td>C518785</td>
  </tr>
</table>

<h3>備考</h3>
<p>
  マイクロUSBのコネクタは撤去しました。<br>
  適宜、5V電源とGNDを用意してください。
</p>


<h3>プログラムでAボタンの連射機能を搭載</h3>
<p>
仙界伝弐のRTA用に<br>
・Aは単発A<br>
・Yを押しっぱでA連射
</p><p>
B押しっぱのA連打でテキスト送りが早くなる仕様のための実装
</p><p>
controller2.inoをArduino Nanoに書き込んでください。
</p>
<p>
※ルール上、連射機能が認められているかどうかは不明です。
  24/10/22時点
</p>


<h3>更新履歴</h3>
<p>
  <b>rev1.5.0(25/06/07)</b><br>
  配置を変更しました。<br>
  HDMIの抜き差し無しで起動できるようになりました。<br>
  使用パーツに変更があります。
</p>
<p>
  <b>rev1.4.0(25/02/07)</b><br>
  配置を変更しました。
</p>
<p>
  <b>rev1.3.6(24/11/02)</b><br>
  配置を変更しました。
</p>
<p>
  <b>rev1.3.1(24/09/27)</b><br>
  配置を変更、パーツを変更しました。
</p>
<p>
  <b>rev1.22(24/09/01)</b><br>
  配置を変更しました。
</p>
<p>
  <b>rev1.1</b><br>
  配置を変更しました。<br>
  が、あまりオススメしません。<br>
  rev1.2をお待ちいただいたほうが良いかもしれません。
</p>
