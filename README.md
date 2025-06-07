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
    <th>リンク</th>
  </tr>
  <tr>
    <th>R1</th>
    <td>10kΩ 抵抗</td>
    <td><a href="https://www.lcsc.com/product-detail/Chip-Resistor-Surface-Mount_UNI-ROYAL-Uniroyal-Elec-0805W8F1002T5E_C17414.html">LCSC</a></td>
  </tr>
  <tr>
    <th>U5</th>
    <td>レギュレーター</td>
    <td><a href="https://www.lcsc.com/product-detail/Voltage-Regulators-Linear-Low-Drop-Out-LDO-Regulators_UTC-Unisonic-Tech-LD1117AG-1-5V_C474401.html">LCSC</a></td>
  </tr>
  <tr>
    <th>C1</th>
    <td>キャパシタ 1206 10uF</td>
    <td><a href="https://item.szlcsc.com/89171.html">LCSC</a></td>
  </tr>
  <tr>
    <th>C2-C4</th>
    <td>キャパシタ 1206 100uF</td>
    <td><a href="https://www.lcsc.com/product-detail/Multilayer-Ceramic-Capacitors-MLCC-SMD-SMT_Chinocera-HGC1206R5107M100NSPJ_C7432784.html">LCSC</a></td>
  </tr>
  <tr>
    <th>Q13</th>
    <td>Pチャンネル MOSFET</td>
    <td><a href="https://www.lcsc.com/product-detail/MOSFETs_HUASHUO-IRLML6402_C518785.html">LCSC</a></td>
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
