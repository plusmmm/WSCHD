# WSCHD
WSCHDの基板です。
<p>
zwenergy氏の作成した「swancolorHD」を基に再設計しました。<br>
swancolorHD<br>
https://github.com/zwenergy/swancolorHD
</p>
<p>
  <img src="https://raw.githubusercontent.com/plusmmm/WSCHD/main/WSC-HD_Rev1.6.0.png" width="30%">
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
    <th>Q14</th>
    <td>レギュレーター</td>
    <td>C7528820</td>
  </tr>
  <tr>
    <th>C2,C3</th>
    <td>キャパシタ 1206 10uF</td>
    <td>C9807</td>
  </tr>
  <tr>
    <th>C4,C5</th>
    <td>キャパシタ 0805 100nF</td>
    <td>C49678</td>
  </tr>
  <tr>
    <th>Q13</th>
    <td>Pチャンネル MOSFET</td>
    <td>C518785</td>
  </tr>
  <tr>
    <th>D1</th>
    <td>ショットキーダイオード</td>
    <td>C83852</td>
  </tr>
</table>

<h3>備考</h3>
<p>
  マイクロUSBのコネクタは撤去しました。<br>
  適宜、5V電源を用意してください。
</p>


<h3>プログラムでAボタンの連射機能を搭載</h3>
<p>
仙界伝弐のRTA用に<br>
・Aは単発A<br>
・Yを押しっぱでA連射
</p><p>
※B押しっぱのA連打でテキスト送りが早くなる仕様のための実装
</p><p>
controller2.inoをArduino Nanoに書き込んでください。
</p>


<h3>更新履歴</h3>
<p>
  <b>rev1.6.0(25/08/24)</b><br>
  各種パーツを見直し/変更、パーツ変更に伴う配線の見直しを行いました。<br>
  FPGAボードでの電源投入を排除したため手動で電源投入できるように配線を行う必要があります。
</p>
<p>
  <b>rev1.5.1(25/06/15)</b><br>
  コンデンサを1つ削除、抵抗を1つ追加しました。
</p>
<p>
  <b>rev1.5.0(25/06/15)</b><br>
  ショットキーダイオードの抜けがありましたので修正しました。
</p>
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
