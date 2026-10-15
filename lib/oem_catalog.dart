enum OemKind { enumValue, boolValue, number }

class OemOption {
  final int value;
  final String label;
  final double? physical;
  const OemOption(this.value, this.label, this.physical);
}

class OemParam {
  final int id;
  final String key;
  final String title;
  final String group;
  final String help;
  final OemKind kind;
  final String optionSpec;
  final int min;
  final int max;
  final String unit;
  final bool hex;
  final bool risky;

  const OemParam({
    required this.id,
    required this.key,
    required this.title,
    required this.group,
    required this.help,
    required this.kind,
    required this.optionSpec,
    required this.min,
    required this.max,
    required this.unit,
    required this.hex,
    required this.risky,
  });

  List<OemOption> get options {
    if (optionSpec.isEmpty) return const [];
    return optionSpec.split('|').map((item) {
      final f = item.split(';');
      return OemOption(
        int.parse(f[0]),
        f.length > 1 ? f[1] : f[0],
        f.length > 2 && f[2].isNotEmpty ? double.tryParse(f[2]) : null,
      );
    }).toList(growable: false);
  }
}

class OemCatalog {
  static const List<OemParam> params = [

    OemParam(
      id: 1, key: 'CHARGE_CURRENT', title: 'Charge current (normal temperature)',
      group: 'Charging', help: 'Configures the charge current applied to the battery during normal temperature conditions (10C < T < +45C). NOTE: Please make sure to call this API at first, before configuring anything else (e.g. ChargeCurrentCold, ChargeCurrentHot, TerminationCurrent, etc.).',
      kind: OemKind.enumValue, optionSpec: '0;5 mA (Low Current Mode);5.0|1;5.5 mA (LCM);5.5|2;6 mA (LCM);6.0|3;6.5 mA (LCM);6.5|4;7 mA (LCM);7.0|5;7.5 mA (LCM);7.5|6;8 mA (LCM);8.0|7;8.5 mA (LCM);8.5|8;9 mA (LCM);9.0|9;9.5 mA (LCM);9.5|10;10 mA (LCM);10.0|11;10.5 mA (LCM);10.5|12;11 mA (LCM);11.0|13;11.5 mA (LCM);11.5|14;12 mA (LCM);12.0|15;12.5 mA (LCM);12.5|16;13 mA (LCM);13.0|17;13.5 mA (LCM);13.5|18;14 mA (LCM);14.0|19;14.5 mA (LCM);14.5|20;15 mA (LCM);15.0|21;15.5 mA (LCM);15.5|22;16 mA (LCM);16.0|23;16.5 mA (LCM);16.5|24;17 mA (LCM);17.0|25;17.5 mA (LCM);17.5|26;18 mA (LCM);18.0|27;18.5 mA (LCM);18.5|28;19 mA (LCM);19.0|29;19.5 mA (LCM);19.5|30;20 mA (LCM);20.0|31;20.5 mA (LCM);20.5|32;21 mA (LCM);21.0|33;22 mA (LCM);22.0|34;23 mA (LCM);23.0|35;24 mA (LCM);24.0|36;25 mA (LCM);25.0|37;26 mA (LCM);26.0|38;27 mA (LCM);27.0|39;28 mA (LCM);28.0|40;29 mA (LCM);29.0|41;30 mA (LCM);30.0|42;31 mA (LCM);31.0|43;32 mA (LCM);32.0|44;33 mA (LCM);33.0|45;34 mA (LCM);34.0|46;35 mA (LCM);35.0|47;36 mA (LCM);36.0|48;37 mA (LCM);37.0|49;38 mA (LCM);38.0|50;39 mA (LCM);39.0|51;40 mA (LCM);40.0|52;41 mA (LCM);41.0|53;42 mA (LCM);42.0|54;43 mA (LCM);43.0|55;45 mA (LCM);45.0|56;46.5 mA (LCM);46.5|57;48 mA (LCM);48.0|58;49.5 mA (LCM);49.5|59;51 mA (LCM);51.0|60;52.5 mA (LCM);52.5|63;0 mA;0.0|128;25 mA (High Current Mode);25.0|129;27.5 mA (HCM);27.5|130;30 mA (HCM);30.0|131;32.5 mA (HCM);32.5|132;35 mA (HCM);35.0|133;37.5 mA (HCM);37.5|134;40 mA (HCM);40.0|135;42.5 mA (HCM);42.5|136;45 mA (HCM);45.0|137;47.5 mA (HCM);47.5|138;50 mA (HCM);50.0|139;52.5 mA (HCM);52.5|140;55 mA (HCM);55.0|141;57.5 mA (HCM);57.5|142;60 mA (HCM);60.0|143;62.5 mA (HCM);62.5|144;65 mA (HCM);65.0|145;67.5 mA (HCM);67.5|146;70 mA (HCM);70.0|147;72.5 mA (HCM);72.5|148;75 mA (HCM);75.0|149;77.5 mA (HCM);77.5|150;80 mA (HCM);80.0|151;82.5 mA (HCM);82.5|152;85 mA (HCM);85.0|153;87.5 mA (HCM);87.5|154;90 mA (HCM);90.0|155;92.5 mA (HCM);92.5|156;95 mA (HCM);95.0|157;97.5 mA (HCM);97.5|158;100 mA (HCM);100.0|159;102.5 mA (HCM);102.5|160;105 mA (HCM);105.0|161;110 mA (HCM);110.0|162;115 mA (HCM);115.0|163;120 mA (HCM);120.0|164;125 mA (HCM);125.0|165;130 mA (HCM);130.0|166;135 mA (HCM);135.0|167;140 mA (HCM);140.0|168;145 mA (HCM);145.0|169;150 mA (HCM);150.0|170;155 mA (HCM);155.0|171;160 mA (HCM);160.0|172;165 mA (HCM);165.0|173;170 mA (HCM);170.0|174;175 mA (HCM);175.0|175;180 mA (HCM);180.0|176;185 mA (HCM);185.0|177;190 mA (HCM);190.0|178;195 mA (HCM);195.0|179;200 mA (HCM);200.0|180;205 mA (HCM);205.0|181;210 mA (HCM);210.0|182;217.5 mA (HCM);217.5|183;225 mA (HCM);225.0|184;232.5 mA (HCM);232.5|185;240 mA (HCM);240.0|186;247.5 mA (HCM);247.5|187;255 mA (HCM);255.0',
      min: 0, max: 187, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 2, key: 'CHARGE_CURRENT_COLD', title: 'Charge current (cold)',
      group: 'Charging', help: 'Configures the CC charge current for cold temperature conditions (0C < T < +10C). NOTE: Please ensure to call RRQ36031_OemConfiguration_SetChargeCurrent() before RRQ36031_OemConfiguration_SetChargeCurrentCold()! Also make sure to select the same current range (LCM or HCM) like in the case of RRQ36031_OemConfiguration_SetChargeCurrent(), otherwise an "InvalidParameter" status will be returned.',
      kind: OemKind.enumValue, optionSpec: '0;5 mA (Low Current Mode);5.0|1;5.5 mA (LCM);5.5|2;6 mA (LCM);6.0|3;6.5 mA (LCM);6.5|4;7 mA (LCM);7.0|5;7.5 mA (LCM);7.5|6;8 mA (LCM);8.0|7;8.5 mA (LCM);8.5|8;9 mA (LCM);9.0|9;9.5 mA (LCM);9.5|10;10 mA (LCM);10.0|11;10.5 mA (LCM);10.5|12;11 mA (LCM);11.0|13;11.5 mA (LCM);11.5|14;12 mA (LCM);12.0|15;12.5 mA (LCM);12.5|16;13 mA (LCM);13.0|17;13.5 mA (LCM);13.5|18;14 mA (LCM);14.0|19;14.5 mA (LCM);14.5|20;15 mA (LCM);15.0|21;15.5 mA (LCM);15.5|22;16 mA (LCM);16.0|23;16.5 mA (LCM);16.5|24;17 mA (LCM);17.0|25;17.5 mA (LCM);17.5|26;18 mA (LCM);18.0|27;18.5 mA (LCM);18.5|28;19 mA (LCM);19.0|29;19.5 mA (LCM);19.5|30;20 mA (LCM);20.0|31;20.5 mA (LCM);20.5|32;21 mA (LCM);21.0|33;22 mA (LCM);22.0|34;23 mA (LCM);23.0|35;24 mA (LCM);24.0|36;25 mA (LCM);25.0|37;26 mA (LCM);26.0|38;27 mA (LCM);27.0|39;28 mA (LCM);28.0|40;29 mA (LCM);29.0|41;30 mA (LCM);30.0|42;31 mA (LCM);31.0|43;32 mA (LCM);32.0|44;33 mA (LCM);33.0|45;34 mA (LCM);34.0|46;35 mA (LCM);35.0|47;36 mA (LCM);36.0|48;37 mA (LCM);37.0|49;38 mA (LCM);38.0|50;39 mA (LCM);39.0|51;40 mA (LCM);40.0|52;41 mA (LCM);41.0|53;42 mA (LCM);42.0|54;43 mA (LCM);43.0|55;45 mA (LCM);45.0|56;46.5 mA (LCM);46.5|57;48 mA (LCM);48.0|58;49.5 mA (LCM);49.5|59;51 mA (LCM);51.0|60;52.5 mA (LCM);52.5|63;0 mA;0.0|128;25 mA (High Current Mode);25.0|129;27.5 mA (HCM);27.5|130;30 mA (HCM);30.0|131;32.5 mA (HCM);32.5|132;35 mA (HCM);35.0|133;37.5 mA (HCM);37.5|134;40 mA (HCM);40.0|135;42.5 mA (HCM);42.5|136;45 mA (HCM);45.0|137;47.5 mA (HCM);47.5|138;50 mA (HCM);50.0|139;52.5 mA (HCM);52.5|140;55 mA (HCM);55.0|141;57.5 mA (HCM);57.5|142;60 mA (HCM);60.0|143;62.5 mA (HCM);62.5|144;65 mA (HCM);65.0|145;67.5 mA (HCM);67.5|146;70 mA (HCM);70.0|147;72.5 mA (HCM);72.5|148;75 mA (HCM);75.0|149;77.5 mA (HCM);77.5|150;80 mA (HCM);80.0|151;82.5 mA (HCM);82.5|152;85 mA (HCM);85.0|153;87.5 mA (HCM);87.5|154;90 mA (HCM);90.0|155;92.5 mA (HCM);92.5|156;95 mA (HCM);95.0|157;97.5 mA (HCM);97.5|158;100 mA (HCM);100.0|159;102.5 mA (HCM);102.5|160;105 mA (HCM);105.0|161;110 mA (HCM);110.0|162;115 mA (HCM);115.0|163;120 mA (HCM);120.0|164;125 mA (HCM);125.0|165;130 mA (HCM);130.0|166;135 mA (HCM);135.0|167;140 mA (HCM);140.0|168;145 mA (HCM);145.0|169;150 mA (HCM);150.0|170;155 mA (HCM);155.0|171;160 mA (HCM);160.0|172;165 mA (HCM);165.0|173;170 mA (HCM);170.0|174;175 mA (HCM);175.0|175;180 mA (HCM);180.0|176;185 mA (HCM);185.0|177;190 mA (HCM);190.0|178;195 mA (HCM);195.0|179;200 mA (HCM);200.0|180;205 mA (HCM);205.0|181;210 mA (HCM);210.0|182;217.5 mA (HCM);217.5|183;225 mA (HCM);225.0|184;232.5 mA (HCM);232.5|185;240 mA (HCM);240.0|186;247.5 mA (HCM);247.5|187;255 mA (HCM);255.0',
      min: 0, max: 187, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 3, key: 'CHARGE_CURRENT_HOT', title: 'Charge current (hot)',
      group: 'Charging', help: 'Configures the CC charge current for hot temperature conditions (+45C < T < +60C). NOTE: Please ensure to call RRQ36031_OemConfiguration_SetChargeCurrent() before RRQ36031_OemConfiguration_SetChargeCurrentHot()! Also make sure to select the same current range (LCM or HCM) like in the case of RRQ36031_OemConfiguration_SetChargeCurrent(), otherwise an "InvalidParameter" status will be returned.',
      kind: OemKind.enumValue, optionSpec: '0;5 mA (Low Current Mode);5.0|1;5.5 mA (LCM);5.5|2;6 mA (LCM);6.0|3;6.5 mA (LCM);6.5|4;7 mA (LCM);7.0|5;7.5 mA (LCM);7.5|6;8 mA (LCM);8.0|7;8.5 mA (LCM);8.5|8;9 mA (LCM);9.0|9;9.5 mA (LCM);9.5|10;10 mA (LCM);10.0|11;10.5 mA (LCM);10.5|12;11 mA (LCM);11.0|13;11.5 mA (LCM);11.5|14;12 mA (LCM);12.0|15;12.5 mA (LCM);12.5|16;13 mA (LCM);13.0|17;13.5 mA (LCM);13.5|18;14 mA (LCM);14.0|19;14.5 mA (LCM);14.5|20;15 mA (LCM);15.0|21;15.5 mA (LCM);15.5|22;16 mA (LCM);16.0|23;16.5 mA (LCM);16.5|24;17 mA (LCM);17.0|25;17.5 mA (LCM);17.5|26;18 mA (LCM);18.0|27;18.5 mA (LCM);18.5|28;19 mA (LCM);19.0|29;19.5 mA (LCM);19.5|30;20 mA (LCM);20.0|31;20.5 mA (LCM);20.5|32;21 mA (LCM);21.0|33;22 mA (LCM);22.0|34;23 mA (LCM);23.0|35;24 mA (LCM);24.0|36;25 mA (LCM);25.0|37;26 mA (LCM);26.0|38;27 mA (LCM);27.0|39;28 mA (LCM);28.0|40;29 mA (LCM);29.0|41;30 mA (LCM);30.0|42;31 mA (LCM);31.0|43;32 mA (LCM);32.0|44;33 mA (LCM);33.0|45;34 mA (LCM);34.0|46;35 mA (LCM);35.0|47;36 mA (LCM);36.0|48;37 mA (LCM);37.0|49;38 mA (LCM);38.0|50;39 mA (LCM);39.0|51;40 mA (LCM);40.0|52;41 mA (LCM);41.0|53;42 mA (LCM);42.0|54;43 mA (LCM);43.0|55;45 mA (LCM);45.0|56;46.5 mA (LCM);46.5|57;48 mA (LCM);48.0|58;49.5 mA (LCM);49.5|59;51 mA (LCM);51.0|60;52.5 mA (LCM);52.5|63;0 mA;0.0|128;25 mA (High Current Mode);25.0|129;27.5 mA (HCM);27.5|130;30 mA (HCM);30.0|131;32.5 mA (HCM);32.5|132;35 mA (HCM);35.0|133;37.5 mA (HCM);37.5|134;40 mA (HCM);40.0|135;42.5 mA (HCM);42.5|136;45 mA (HCM);45.0|137;47.5 mA (HCM);47.5|138;50 mA (HCM);50.0|139;52.5 mA (HCM);52.5|140;55 mA (HCM);55.0|141;57.5 mA (HCM);57.5|142;60 mA (HCM);60.0|143;62.5 mA (HCM);62.5|144;65 mA (HCM);65.0|145;67.5 mA (HCM);67.5|146;70 mA (HCM);70.0|147;72.5 mA (HCM);72.5|148;75 mA (HCM);75.0|149;77.5 mA (HCM);77.5|150;80 mA (HCM);80.0|151;82.5 mA (HCM);82.5|152;85 mA (HCM);85.0|153;87.5 mA (HCM);87.5|154;90 mA (HCM);90.0|155;92.5 mA (HCM);92.5|156;95 mA (HCM);95.0|157;97.5 mA (HCM);97.5|158;100 mA (HCM);100.0|159;102.5 mA (HCM);102.5|160;105 mA (HCM);105.0|161;110 mA (HCM);110.0|162;115 mA (HCM);115.0|163;120 mA (HCM);120.0|164;125 mA (HCM);125.0|165;130 mA (HCM);130.0|166;135 mA (HCM);135.0|167;140 mA (HCM);140.0|168;145 mA (HCM);145.0|169;150 mA (HCM);150.0|170;155 mA (HCM);155.0|171;160 mA (HCM);160.0|172;165 mA (HCM);165.0|173;170 mA (HCM);170.0|174;175 mA (HCM);175.0|175;180 mA (HCM);180.0|176;185 mA (HCM);185.0|177;190 mA (HCM);190.0|178;195 mA (HCM);195.0|179;200 mA (HCM);200.0|180;205 mA (HCM);205.0|181;210 mA (HCM);210.0|182;217.5 mA (HCM);217.5|183;225 mA (HCM);225.0|184;232.5 mA (HCM);232.5|185;240 mA (HCM);240.0|186;247.5 mA (HCM);247.5|187;255 mA (HCM);255.0',
      min: 0, max: 187, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 4, key: 'TERMINATION_CURRENT', title: 'Termination current',
      group: 'Charging', help: 'Configures the termination current. If the charging current drops below the set threshold, charging will be terminated. NOTE: Please ensure to call RRQ36031_OemConfiguration_SetChargeCurrent() before RRQ36031_OemConfiguration_SetTerminationCurrent()! Also make sure to select the same current range (LCM or HCM) like in the case of RRQ36031_OemConfiguration_SetChargeCurrent(), otherwise an "InvalidParameter" status will be returned.',
      kind: OemKind.enumValue, optionSpec: '0;0.5 mA;0.5|1;1 mA;1.0|2;1.5 mA;1.5|3;2 mA;2.0|4;2.5 mA;2.5|5;3 mA;3.0|6;3.5 mA;3.5|7;4 mA;4.0|8;4.5 mA;4.5|9;5 mA;5.0|10;5.5 mA;5.5|11;6 mA;6.0|12;6.5 mA;6.5|13;7 mA;7.0|14;7.5 mA;7.5|15;8 mA;8.0|128;2.5 mA;2.5|129;5 mA;5.0|130;7.5 mA;7.5|131;10 mA;10.0|132;12.5 mA;12.5|133;15 mA;15.0|134;17.5 mA;17.5|135;20 mA;20.0|136;22.5 mA;22.5|137;25 mA;25.0|138;27.5 mA;27.5|139;30 mA;30.0|140;32.5 mA;32.5|141;35 mA;35.0|142;37.5 mA;37.5|143;40 mA;40.0',
      min: 0, max: 143, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 5, key: 'TRICKLE_VOLTAGE', title: 'Trickle charge voltage threshold',
      group: 'Charging', help: 'Configures the trickle charge voltage threshold. If the battery is below the set voltage threshold, then the trickle charging current will be applied.',
      kind: OemKind.enumValue, optionSpec: '0;2.6 V (under-voltage lockout @2.5 V);2600.0|1;2.7 V (under-voltage lockout @2.6 V);2700.0|2;2.8 V (under-voltage lockout @2.7 V);2800.0|3;2.9 V (under-voltage lockout @2.8 V);2900.0|4;3.0 V (under-voltage lockout @2.9 V);3000.0|5;3.1 V (under-voltage lockout @3.0 V);3100.0|6;3.2 V (under-voltage lockout @3.1 V);3200.0|7;3.3 V (under-voltage lockout @3.2 V);3300.0',
      min: 0, max: 7, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 6, key: 'TERMINATION_VOLTAGE', title: 'Termination voltage (normal temperature)',
      group: 'Charging', help: 'Configures the termination voltage during normal temperature conditions (10C < T < +45C). When the battery reaches the set voltage, the voltage will be held, while the charging current tapers off. The value defines the transition from CC phase to CV phase.',
      kind: OemKind.enumValue, optionSpec: '0;3.59 V;3590.0|1;3.62 V;3620.0|2;3.65 V;3650.0|3;3.67 V;3670.0|4;3.70 V;3700.0|5;3.73 V;3730.0|6;3.75 V;3750.0|7;3.81 V;3810.0|8;3.83 V;3830.0|9;3.86 V;3860.0|10;3.91 V;3910.0|11;3.94 V;3940.0|12;3.97 V;3970.0|13;3.02 V;3020.0|14;3.08 V;3080.0|15;4.13 V;4130.0|16;4.16 V;4160.0|17;4.18 V;4180.0|18;4.24 V;4240.0|19;4.26 V;4260.0|20;4.29 V;4290.0|21;4.32 V;4320.0|22;4.34 V;4340.0|23;4.40 V;4400.0|24;4.42 V;4420.0|25;4.45 V;4450.0|26;4.51 V;4510.0|27;4.53 V;4530.0|28;4.56 V;4560.0|29;4.59 V;4590.0|30;4.61 V;4610.0|31;4.65 V;4650.0',
      min: 0, max: 31, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 7, key: 'TERMINATION_VOLTAGE_COLD', title: 'Termination voltage (cold)',
      group: 'Charging', help: 'Configures the termination voltage for cold temperature conditions (0C < T < +10C).',
      kind: OemKind.enumValue, optionSpec: '0;3.59 V;3590.0|1;3.62 V;3620.0|2;3.65 V;3650.0|3;3.67 V;3670.0|4;3.70 V;3700.0|5;3.73 V;3730.0|6;3.75 V;3750.0|7;3.81 V;3810.0|8;3.83 V;3830.0|9;3.86 V;3860.0|10;3.91 V;3910.0|11;3.94 V;3940.0|12;3.97 V;3970.0|13;3.02 V;3020.0|14;3.08 V;3080.0|15;4.13 V;4130.0|16;4.16 V;4160.0|17;4.18 V;4180.0|18;4.24 V;4240.0|19;4.26 V;4260.0|20;4.29 V;4290.0|21;4.32 V;4320.0|22;4.34 V;4340.0|23;4.40 V;4400.0|24;4.42 V;4420.0|25;4.45 V;4450.0|26;4.51 V;4510.0|27;4.53 V;4530.0|28;4.56 V;4560.0|29;4.59 V;4590.0|30;4.61 V;4610.0|31;4.65 V;4650.0',
      min: 0, max: 31, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 8, key: 'TERMINATION_VOLTAGE_HOT', title: 'Termination voltage (hot)',
      group: 'Charging', help: 'Configures the termination voltage for hot temperature conditions (+45C < T < +60C).',
      kind: OemKind.enumValue, optionSpec: '0;3.59 V;3590.0|1;3.62 V;3620.0|2;3.65 V;3650.0|3;3.67 V;3670.0|4;3.70 V;3700.0|5;3.73 V;3730.0|6;3.75 V;3750.0|7;3.81 V;3810.0|8;3.83 V;3830.0|9;3.86 V;3860.0|10;3.91 V;3910.0|11;3.94 V;3940.0|12;3.97 V;3970.0|13;3.02 V;3020.0|14;3.08 V;3080.0|15;4.13 V;4130.0|16;4.16 V;4160.0|17;4.18 V;4180.0|18;4.24 V;4240.0|19;4.26 V;4260.0|20;4.29 V;4290.0|21;4.32 V;4320.0|22;4.34 V;4340.0|23;4.40 V;4400.0|24;4.42 V;4420.0|25;4.45 V;4450.0|26;4.51 V;4510.0|27;4.53 V;4530.0|28;4.56 V;4560.0|29;4.59 V;4590.0|30;4.61 V;4610.0|31;4.65 V;4650.0',
      min: 0, max: 31, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 9, key: 'RECHARGE_VOLTAGE', title: 'Recharge voltage threshold',
      group: 'Charging', help: 'Configures the recharge voltage threshold. When the battery voltage falls below the set threshold, charging will commence again.',
      kind: OemKind.enumValue, optionSpec: '0;2400 mV;2400.0|1;2412 mV;2412.0|2;2425 mV;2425.0|3;2438 mV;2438.0|4;2450 mV;2450.0|5;2462 mV;2462.0|6;2475 mV;2475.0|7;2488 mV;2488.0|8;2500 mV;2500.0|9;2512 mV;2512.0|10;2525 mV;2525.0|11;2538 mV;2538.0|12;2550 mV;2550.0|13;2562 mV;2562.0|14;2575 mV;2575.0|15;2588 mV;2588.0|16;2600 mV;2600.0|17;2612 mV;2612.0|18;2625 mV;2625.0|19;2638 mV;2638.0|20;2650 mV;2650.0|21;2662 mV;2662.0|22;2675 mV;2675.0|23;2688 mV;2688.0|24;2700 mV;2700.0|25;2712 mV;2712.0|26;2725 mV;2725.0|27;2738 mV;2738.0|28;2750 mV;2750.0|29;2762 mV;2762.0|30;2775 mV;2775.0|31;2788 mV;2788.0|32;2800 mV;2800.0|33;2812 mV;2812.0|34;2825 mV;2825.0|35;2838 mV;2838.0|36;2850 mV;2850.0|37;2862 mV;2862.0|38;2875 mV;2875.0|39;2888 mV;2888.0|40;2900 mV;2900.0|41;2912 mV;2912.0|42;2925 mV;2925.0|43;2938 mV;2938.0|44;2950 mV;2950.0|45;2962 mV;2962.0|46;2975 mV;2975.0|47;2988 mV;2988.0|48;3000 mV;3000.0|49;3012 mV;3012.0|50;3025 mV;3025.0|51;3038 mV;3038.0|52;3050 mV;3050.0|53;3062 mV;3062.0|54;3075 mV;3075.0|55;3088 mV;3088.0|56;3100 mV;3100.0|57;3112 mV;3112.0|58;3125 mV;3125.0|59;3138 mV;3138.0|60;3150 mV;3150.0|61;3162 mV;3162.0|62;3175 mV;3175.0|63;3188 mV;3188.0|64;3200 mV;3200.0|65;3212 mV;3212.0|66;3225 mV;3225.0|67;3238 mV;3238.0|68;3250 mV;3250.0|69;3262 mV;3262.0|70;3275 mV;3275.0|71;3288 mV;3288.0|72;3300 mV;3300.0|73;3312 mV;3312.0|74;3325 mV;3325.0|75;3338 mV;3338.0|76;3350 mV;3350.0|77;3362 mV;3362.0|78;3375 mV;3375.0|79;3388 mV;3388.0|80;3400 mV;3400.0|81;3412 mV;3412.0|82;3425 mV;3425.0|83;3438 mV;3438.0|84;3450 mV;3450.0|85;3462 mV;3462.0|86;3475 mV;3475.0|87;3488 mV;3488.0|88;3500 mV;3500.0|89;3512 mV;3512.0|90;3525 mV;3525.0|91;3538 mV;3538.0|92;3550 mV;3550.0|93;3562 mV;3562.0|94;3575 mV;3575.0|95;3588 mV;3588.0|96;3600 mV;3600.0|97;3612 mV;3612.0|98;3625 mV;3625.0|99;3638 mV;3638.0|100;3650 mV;3650.0|101;3662 mV;3662.0|102;3675 mV;3675.0|103;3688 mV;3688.0|104;3700 mV;3700.0|105;3712 mV;3712.0|106;3725 mV;3725.0|107;3738 mV;3738.0|108;3750 mV;3750.0|109;3762 mV;3762.0|110;3775 mV;3775.0|111;3788 mV;3788.0|112;3800 mV;3800.0|113;3812 mV;3812.0|114;3825 mV;3825.0|115;3838 mV;3838.0|116;3850 mV;3850.0|117;3862 mV;3862.0|118;3875 mV;3875.0|119;3888 mV;3888.0|120;3900 mV;3900.0|121;3912 mV;3912.0|122;3925 mV;3925.0|123;3938 mV;3938.0|124;3950 mV;3950.0|125;3962 mV;3962.0|126;3975 mV;3975.0|127;3988 mV;3988.0|128;4000 mV;4000.0|129;4012 mV;4012.0|130;4025 mV;4025.0|131;4038 mV;4038.0|132;4050 mV;4050.0|133;4062 mV;4062.0|134;4075 mV;4075.0|135;4088 mV;4088.0|136;4100 mV;4100.0|137;4112 mV;4112.0|138;4125 mV;4125.0|139;4138 mV;4138.0|140;4150 mV;4150.0|141;4162 mV;4162.0|142;4175 mV;4175.0|143;4188 mV;4188.0|144;4200 mV;4200.0|145;4212 mV;4212.0|146;4225 mV;4225.0|147;4238 mV;4238.0|148;4250 mV;4250.0|149;4262 mV;4262.0|150;4275 mV;4275.0|151;4288 mV;4288.0|152;4300 mV;4300.0|153;4312 mV;4312.0|154;4325 mV;4325.0|155;4338 mV;4338.0|156;4350 mV;4350.0|157;4362 mV;4362.0|158;4375 mV;4375.0|159;4388 mV;4388.0|160;4400 mV;4400.0|161;4412 mV;4412.0|162;4425 mV;4425.0|163;4438 mV;4438.0|164;4450 mV;4450.0|165;4462 mV;4462.0|166;4475 mV;4475.0|167;4488 mV;4488.0|168;4500 mV;4500.0|169;4512 mV;4512.0|170;4525 mV;4525.0|171;4538 mV;4538.0|172;4550 mV;4550.0|173;4562 mV;4562.0|174;4575 mV;4575.0|175;4588 mV;4588.0|176;4600 mV;4600.0|177;4612 mV;4612.0|178;4625 mV;4625.0|179;4638 mV;4638.0|180;4650 mV;4650.0|181;4662 mV;4662.0|182;4675 mV;4675.0|183;4688 mV;4688.0|184;4700 mV;4700.0|185;4712 mV;4712.0|186;4725 mV;4725.0|187;4738 mV;4738.0|188;4750 mV;4750.0|189;4762 mV;4762.0|190;4775 mV;4775.0|191;4788 mV;4788.0|192;4800 mV;4800.0|193;4812 mV;4812.0|194;4825 mV;4825.0|195;4838 mV;4838.0|196;4850 mV;4850.0|197;4862 mV;4862.0|198;4875 mV;4875.0|199;4888 mV;4888.0|200;4900 mV;4900.0|201;4912 mV;4912.0|202;4925 mV;4925.0|203;4938 mV;4938.0|204;4950 mV;4950.0|205;4962 mV;4962.0|206;4975 mV;4975.0|207;4988 mV;4988.0|208;5000 mV;5000.0|209;5012 mV;5012.0|210;5025 mV;5025.0|211;5038 mV;5038.0|212;5050 mV;5050.0|213;5062 mV;5062.0|214;5075 mV;5075.0|215;5088 mV;5088.0|216;5100 mV;5100.0|217;5112 mV;5112.0|218;5125 mV;5125.0|219;5138 mV;5138.0|220;5150 mV;5150.0|221;5162 mV;5162.0|222;5175 mV;5175.0|223;5188 mV;5188.0|224;5200 mV;5200.0|225;5212 mV;5212.0|226;5225 mV;5225.0|227;5238 mV;5238.0|228;5250 mV;5250.0|229;5262 mV;5262.0|230;5275 mV;5275.0|231;5288 mV;5288.0|232;5300 mV;5300.0|233;5312 mV;5312.0|234;5325 mV;5325.0|235;5338 mV;5338.0|236;5350 mV;5350.0|237;5362 mV;5362.0|238;5375 mV;5375.0|239;5388 mV;5388.0|240;5400 mV;5400.0|241;5412 mV;5412.0|242;5425 mV;5425.0|243;5438 mV;5438.0|244;5450 mV;5450.0|245;5462 mV;5462.0|246;5475 mV;5475.0|247;5488 mV;5488.0|248;5500 mV;5500.0|249;5512 mV;5512.0|250;5525 mV;5525.0|251;5538 mV;5538.0|252;5550 mV;5550.0|253;5562 mV;5562.0|254;5575 mV;5575.0|255;5588 mV;5588.0',
      min: 0, max: 255, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 10, key: 'UNDER_VOLTAGE_LOCKOUT', title: 'Under-voltage lockout',
      group: 'Battery protection', help: 'Configures the under voltage lockout. When VdBat is less than the configured TrickleVoltage - 100mV, the system will shutdown itself to prevent the battery voltage from dropping any further.',
      kind: OemKind.boolValue, optionSpec: '0;Disabled;|1;Enabled;',
      min: 0, max: 1, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 11, key: 'DEAD_BATTERY_DETECTION', title: 'Dead battery detection',
      group: 'Battery protection', help: 'Configures the dead battery detection mechanism. If enabled, batteries below 2V will not be charged anymore for safety reasons. Note: In case a battery with an integrated battery protection circuit is connected to VdBat, please disable this feature.',
      kind: OemKind.boolValue, optionSpec: '0;Disabled;|1;Enabled;',
      min: 0, max: 1, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 12, key: 'CHARGER_ENABLE', title: 'Internal charger',
      group: 'Charging', help: 'Enables/Disabled the internal battery charger.',
      kind: OemKind.boolValue, optionSpec: '1;Enabled;',
      min: 1, max: 1, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 13, key: 'POWER_REGULATION_LOOP', title: 'Power regulation loop',
      group: 'Power regulation', help: 'Selects the Power Regulation Loop (PRL) to be used by the RRQ36031 for power negotiation.',
      kind: OemKind.enumValue, optionSpec: '0;Power regulation loop configured to internal charger;|1;Power regulation loop configured to external charger regulating on battery voltage;|2;Power regulation loop configured to external charger regulating on Vddc voltage;',
      min: 0, max: 2, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 14, key: 'TRICKLE_SUPPLY_CURRENT', title: 'Supply current during trickle charge',
      group: 'Charging', help: 'Defines the minimum amount of power available via VdMcu/VdSys during trickle charging.',
      kind: OemKind.enumValue, optionSpec: '0;VdMcu/VdSys disabled;|1;2 mA (up to 5 mA);2.0|2;5 mA (up to 10 mA);5.0|3;10 mA (up to 20 mA);10.0',
      min: 0, max: 3, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 15, key: 'NTC_MODE', title: 'NTC mode',
      group: 'Temperature (NTC)', help: 'Sets the NTC mode which can either be a single or two-wire measurement.',
      kind: OemKind.enumValue, optionSpec: '0;NTC disabled;|1;NTC configured to single pin measurement;|2;NTC configured to dual pin measurement;',
      min: 0, max: 2, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 16, key: 'NTC_BETA', title: 'NTC beta value',
      group: 'Temperature (NTC)', help: 'Sets the beta value for the connected NTC.',
      kind: OemKind.enumValue, optionSpec: '0;NTC beta set 3380K;|1;NTC beta set 3435K;|2;NTC beta set 3940K;|3;NTC beta set 4050K;|4;NTC beta set 4100K;|5;NTC beta set 4250K;|6;NTC beta set 4550K;',
      min: 0, max: 6, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 17, key: 'VDDC_HIGH_THRESHOLD', title: 'VDDC regulation threshold, high',
      group: 'Power regulation', help: 'Sets the VddC high threshold. When the PRL is set to PowerRegulationLoop_ExternalVddc, or to PowerRegulationLoop_Internal (in the specific case where the battery is already fully charged), the device requests power levels from the Poller in such a way that the voltage on the VddC rail is maintained within a defined range, bounded by VddcLowThreshold and VddcHighThreshold.',
      kind: OemKind.enumValue, optionSpec: '0;2400 mV;2400.0|1;2412 mV;2412.0|2;2425 mV;2425.0|3;2438 mV;2438.0|4;2450 mV;2450.0|5;2462 mV;2462.0|6;2475 mV;2475.0|7;2488 mV;2488.0|8;2500 mV;2500.0|9;2512 mV;2512.0|10;2525 mV;2525.0|11;2538 mV;2538.0|12;2550 mV;2550.0|13;2562 mV;2562.0|14;2575 mV;2575.0|15;2588 mV;2588.0|16;2600 mV;2600.0|17;2612 mV;2612.0|18;2625 mV;2625.0|19;2638 mV;2638.0|20;2650 mV;2650.0|21;2662 mV;2662.0|22;2675 mV;2675.0|23;2688 mV;2688.0|24;2700 mV;2700.0|25;2712 mV;2712.0|26;2725 mV;2725.0|27;2738 mV;2738.0|28;2750 mV;2750.0|29;2762 mV;2762.0|30;2775 mV;2775.0|31;2788 mV;2788.0|32;2800 mV;2800.0|33;2812 mV;2812.0|34;2825 mV;2825.0|35;2838 mV;2838.0|36;2850 mV;2850.0|37;2862 mV;2862.0|38;2875 mV;2875.0|39;2888 mV;2888.0|40;2900 mV;2900.0|41;2912 mV;2912.0|42;2925 mV;2925.0|43;2938 mV;2938.0|44;2950 mV;2950.0|45;2962 mV;2962.0|46;2975 mV;2975.0|47;2988 mV;2988.0|48;3000 mV;3000.0|49;3012 mV;3012.0|50;3025 mV;3025.0|51;3038 mV;3038.0|52;3050 mV;3050.0|53;3062 mV;3062.0|54;3075 mV;3075.0|55;3088 mV;3088.0|56;3100 mV;3100.0|57;3112 mV;3112.0|58;3125 mV;3125.0|59;3138 mV;3138.0|60;3150 mV;3150.0|61;3162 mV;3162.0|62;3175 mV;3175.0|63;3188 mV;3188.0|64;3200 mV;3200.0|65;3212 mV;3212.0|66;3225 mV;3225.0|67;3238 mV;3238.0|68;3250 mV;3250.0|69;3262 mV;3262.0|70;3275 mV;3275.0|71;3288 mV;3288.0|72;3300 mV;3300.0|73;3312 mV;3312.0|74;3325 mV;3325.0|75;3338 mV;3338.0|76;3350 mV;3350.0|77;3362 mV;3362.0|78;3375 mV;3375.0|79;3388 mV;3388.0|80;3400 mV;3400.0|81;3412 mV;3412.0|82;3425 mV;3425.0|83;3438 mV;3438.0|84;3450 mV;3450.0|85;3462 mV;3462.0|86;3475 mV;3475.0|87;3488 mV;3488.0|88;3500 mV;3500.0|89;3512 mV;3512.0|90;3525 mV;3525.0|91;3538 mV;3538.0|92;3550 mV;3550.0|93;3562 mV;3562.0|94;3575 mV;3575.0|95;3588 mV;3588.0|96;3600 mV;3600.0|97;3612 mV;3612.0|98;3625 mV;3625.0|99;3638 mV;3638.0|100;3650 mV;3650.0|101;3662 mV;3662.0|102;3675 mV;3675.0|103;3688 mV;3688.0|104;3700 mV;3700.0|105;3712 mV;3712.0|106;3725 mV;3725.0|107;3738 mV;3738.0|108;3750 mV;3750.0|109;3762 mV;3762.0|110;3775 mV;3775.0|111;3788 mV;3788.0|112;3800 mV;3800.0|113;3812 mV;3812.0|114;3825 mV;3825.0|115;3838 mV;3838.0|116;3850 mV;3850.0|117;3862 mV;3862.0|118;3875 mV;3875.0|119;3888 mV;3888.0|120;3900 mV;3900.0|121;3912 mV;3912.0|122;3925 mV;3925.0|123;3938 mV;3938.0|124;3950 mV;3950.0|125;3962 mV;3962.0|126;3975 mV;3975.0|127;3988 mV;3988.0|128;4000 mV;4000.0|129;4012 mV;4012.0|130;4025 mV;4025.0|131;4038 mV;4038.0|132;4050 mV;4050.0|133;4062 mV;4062.0|134;4075 mV;4075.0|135;4088 mV;4088.0|136;4100 mV;4100.0|137;4112 mV;4112.0|138;4125 mV;4125.0|139;4138 mV;4138.0|140;4150 mV;4150.0|141;4162 mV;4162.0|142;4175 mV;4175.0|143;4188 mV;4188.0|144;4200 mV;4200.0|145;4212 mV;4212.0|146;4225 mV;4225.0|147;4238 mV;4238.0|148;4250 mV;4250.0|149;4262 mV;4262.0|150;4275 mV;4275.0|151;4288 mV;4288.0|152;4300 mV;4300.0|153;4312 mV;4312.0|154;4325 mV;4325.0|155;4338 mV;4338.0|156;4350 mV;4350.0|157;4362 mV;4362.0|158;4375 mV;4375.0|159;4388 mV;4388.0|160;4400 mV;4400.0|161;4412 mV;4412.0|162;4425 mV;4425.0|163;4438 mV;4438.0|164;4450 mV;4450.0|165;4462 mV;4462.0|166;4475 mV;4475.0|167;4488 mV;4488.0|168;4500 mV;4500.0|169;4512 mV;4512.0|170;4525 mV;4525.0|171;4538 mV;4538.0|172;4550 mV;4550.0|173;4562 mV;4562.0|174;4575 mV;4575.0|175;4588 mV;4588.0|176;4600 mV;4600.0|177;4612 mV;4612.0|178;4625 mV;4625.0|179;4638 mV;4638.0|180;4650 mV;4650.0|181;4662 mV;4662.0|182;4675 mV;4675.0|183;4688 mV;4688.0|184;4700 mV;4700.0|185;4712 mV;4712.0|186;4725 mV;4725.0|187;4738 mV;4738.0|188;4750 mV;4750.0|189;4762 mV;4762.0|190;4775 mV;4775.0|191;4788 mV;4788.0|192;4800 mV;4800.0|193;4812 mV;4812.0|194;4825 mV;4825.0|195;4838 mV;4838.0|196;4850 mV;4850.0|197;4862 mV;4862.0|198;4875 mV;4875.0|199;4888 mV;4888.0|200;4900 mV;4900.0|201;4912 mV;4912.0|202;4925 mV;4925.0|203;4938 mV;4938.0|204;4950 mV;4950.0|205;4962 mV;4962.0|206;4975 mV;4975.0|207;4988 mV;4988.0|208;5000 mV;5000.0|209;5012 mV;5012.0|210;5025 mV;5025.0|211;5038 mV;5038.0|212;5050 mV;5050.0|213;5062 mV;5062.0|214;5075 mV;5075.0|215;5088 mV;5088.0|216;5100 mV;5100.0|217;5112 mV;5112.0|218;5125 mV;5125.0|219;5138 mV;5138.0|220;5150 mV;5150.0|221;5162 mV;5162.0|222;5175 mV;5175.0|223;5188 mV;5188.0|224;5200 mV;5200.0|225;5212 mV;5212.0|226;5225 mV;5225.0|227;5238 mV;5238.0|228;5250 mV;5250.0|229;5262 mV;5262.0|230;5275 mV;5275.0|231;5288 mV;5288.0|232;5300 mV;5300.0|233;5312 mV;5312.0|234;5325 mV;5325.0|235;5338 mV;5338.0|236;5350 mV;5350.0|237;5362 mV;5362.0|238;5375 mV;5375.0|239;5388 mV;5388.0|240;5400 mV;5400.0|241;5412 mV;5412.0|242;5425 mV;5425.0|243;5438 mV;5438.0|244;5450 mV;5450.0|245;5462 mV;5462.0|246;5475 mV;5475.0|247;5488 mV;5488.0|248;5500 mV;5500.0|249;5512 mV;5512.0|250;5525 mV;5525.0|251;5538 mV;5538.0|252;5550 mV;5550.0|253;5562 mV;5562.0|254;5575 mV;5575.0|255;5588 mV;5588.0',
      min: 0, max: 255, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 18, key: 'VDDC_LOW_THRESHOLD', title: 'VDDC regulation threshold, low',
      group: 'Power regulation', help: 'Sets the VddC low threshold. When the PRL is set to PowerRegulationLoop_ExternalVddc, or to PowerRegulationLoop_Internal (in the specific case where the battery is already fully charged), the device requests power levels from the Poller in such a way that the voltage on the VddC rail is maintained within a defined range, bounded by VddcLowThreshold and VddcHighThreshold.',
      kind: OemKind.enumValue, optionSpec: '0;2400 mV;2400.0|1;2412 mV;2412.0|2;2425 mV;2425.0|3;2438 mV;2438.0|4;2450 mV;2450.0|5;2462 mV;2462.0|6;2475 mV;2475.0|7;2488 mV;2488.0|8;2500 mV;2500.0|9;2512 mV;2512.0|10;2525 mV;2525.0|11;2538 mV;2538.0|12;2550 mV;2550.0|13;2562 mV;2562.0|14;2575 mV;2575.0|15;2588 mV;2588.0|16;2600 mV;2600.0|17;2612 mV;2612.0|18;2625 mV;2625.0|19;2638 mV;2638.0|20;2650 mV;2650.0|21;2662 mV;2662.0|22;2675 mV;2675.0|23;2688 mV;2688.0|24;2700 mV;2700.0|25;2712 mV;2712.0|26;2725 mV;2725.0|27;2738 mV;2738.0|28;2750 mV;2750.0|29;2762 mV;2762.0|30;2775 mV;2775.0|31;2788 mV;2788.0|32;2800 mV;2800.0|33;2812 mV;2812.0|34;2825 mV;2825.0|35;2838 mV;2838.0|36;2850 mV;2850.0|37;2862 mV;2862.0|38;2875 mV;2875.0|39;2888 mV;2888.0|40;2900 mV;2900.0|41;2912 mV;2912.0|42;2925 mV;2925.0|43;2938 mV;2938.0|44;2950 mV;2950.0|45;2962 mV;2962.0|46;2975 mV;2975.0|47;2988 mV;2988.0|48;3000 mV;3000.0|49;3012 mV;3012.0|50;3025 mV;3025.0|51;3038 mV;3038.0|52;3050 mV;3050.0|53;3062 mV;3062.0|54;3075 mV;3075.0|55;3088 mV;3088.0|56;3100 mV;3100.0|57;3112 mV;3112.0|58;3125 mV;3125.0|59;3138 mV;3138.0|60;3150 mV;3150.0|61;3162 mV;3162.0|62;3175 mV;3175.0|63;3188 mV;3188.0|64;3200 mV;3200.0|65;3212 mV;3212.0|66;3225 mV;3225.0|67;3238 mV;3238.0|68;3250 mV;3250.0|69;3262 mV;3262.0|70;3275 mV;3275.0|71;3288 mV;3288.0|72;3300 mV;3300.0|73;3312 mV;3312.0|74;3325 mV;3325.0|75;3338 mV;3338.0|76;3350 mV;3350.0|77;3362 mV;3362.0|78;3375 mV;3375.0|79;3388 mV;3388.0|80;3400 mV;3400.0|81;3412 mV;3412.0|82;3425 mV;3425.0|83;3438 mV;3438.0|84;3450 mV;3450.0|85;3462 mV;3462.0|86;3475 mV;3475.0|87;3488 mV;3488.0|88;3500 mV;3500.0|89;3512 mV;3512.0|90;3525 mV;3525.0|91;3538 mV;3538.0|92;3550 mV;3550.0|93;3562 mV;3562.0|94;3575 mV;3575.0|95;3588 mV;3588.0|96;3600 mV;3600.0|97;3612 mV;3612.0|98;3625 mV;3625.0|99;3638 mV;3638.0|100;3650 mV;3650.0|101;3662 mV;3662.0|102;3675 mV;3675.0|103;3688 mV;3688.0|104;3700 mV;3700.0|105;3712 mV;3712.0|106;3725 mV;3725.0|107;3738 mV;3738.0|108;3750 mV;3750.0|109;3762 mV;3762.0|110;3775 mV;3775.0|111;3788 mV;3788.0|112;3800 mV;3800.0|113;3812 mV;3812.0|114;3825 mV;3825.0|115;3838 mV;3838.0|116;3850 mV;3850.0|117;3862 mV;3862.0|118;3875 mV;3875.0|119;3888 mV;3888.0|120;3900 mV;3900.0|121;3912 mV;3912.0|122;3925 mV;3925.0|123;3938 mV;3938.0|124;3950 mV;3950.0|125;3962 mV;3962.0|126;3975 mV;3975.0|127;3988 mV;3988.0|128;4000 mV;4000.0|129;4012 mV;4012.0|130;4025 mV;4025.0|131;4038 mV;4038.0|132;4050 mV;4050.0|133;4062 mV;4062.0|134;4075 mV;4075.0|135;4088 mV;4088.0|136;4100 mV;4100.0|137;4112 mV;4112.0|138;4125 mV;4125.0|139;4138 mV;4138.0|140;4150 mV;4150.0|141;4162 mV;4162.0|142;4175 mV;4175.0|143;4188 mV;4188.0|144;4200 mV;4200.0|145;4212 mV;4212.0|146;4225 mV;4225.0|147;4238 mV;4238.0|148;4250 mV;4250.0|149;4262 mV;4262.0|150;4275 mV;4275.0|151;4288 mV;4288.0|152;4300 mV;4300.0|153;4312 mV;4312.0|154;4325 mV;4325.0|155;4338 mV;4338.0|156;4350 mV;4350.0|157;4362 mV;4362.0|158;4375 mV;4375.0|159;4388 mV;4388.0|160;4400 mV;4400.0|161;4412 mV;4412.0|162;4425 mV;4425.0|163;4438 mV;4438.0|164;4450 mV;4450.0|165;4462 mV;4462.0|166;4475 mV;4475.0|167;4488 mV;4488.0|168;4500 mV;4500.0|169;4512 mV;4512.0|170;4525 mV;4525.0|171;4538 mV;4538.0|172;4550 mV;4550.0|173;4562 mV;4562.0|174;4575 mV;4575.0|175;4588 mV;4588.0|176;4600 mV;4600.0|177;4612 mV;4612.0|178;4625 mV;4625.0|179;4638 mV;4638.0|180;4650 mV;4650.0|181;4662 mV;4662.0|182;4675 mV;4675.0|183;4688 mV;4688.0|184;4700 mV;4700.0|185;4712 mV;4712.0|186;4725 mV;4725.0|187;4738 mV;4738.0|188;4750 mV;4750.0|189;4762 mV;4762.0|190;4775 mV;4775.0|191;4788 mV;4788.0|192;4800 mV;4800.0|193;4812 mV;4812.0|194;4825 mV;4825.0|195;4838 mV;4838.0|196;4850 mV;4850.0|197;4862 mV;4862.0|198;4875 mV;4875.0|199;4888 mV;4888.0|200;4900 mV;4900.0|201;4912 mV;4912.0|202;4925 mV;4925.0|203;4938 mV;4938.0|204;4950 mV;4950.0|205;4962 mV;4962.0|206;4975 mV;4975.0|207;4988 mV;4988.0|208;5000 mV;5000.0|209;5012 mV;5012.0|210;5025 mV;5025.0|211;5038 mV;5038.0|212;5050 mV;5050.0|213;5062 mV;5062.0|214;5075 mV;5075.0|215;5088 mV;5088.0|216;5100 mV;5100.0|217;5112 mV;5112.0|218;5125 mV;5125.0|219;5138 mV;5138.0|220;5150 mV;5150.0|221;5162 mV;5162.0|222;5175 mV;5175.0|223;5188 mV;5188.0|224;5200 mV;5200.0|225;5212 mV;5212.0|226;5225 mV;5225.0|227;5238 mV;5238.0|228;5250 mV;5250.0|229;5262 mV;5262.0|230;5275 mV;5275.0|231;5288 mV;5288.0|232;5300 mV;5300.0|233;5312 mV;5312.0|234;5325 mV;5325.0|235;5338 mV;5338.0|236;5350 mV;5350.0|237;5362 mV;5362.0|238;5375 mV;5375.0|239;5388 mV;5388.0|240;5400 mV;5400.0|241;5412 mV;5412.0|242;5425 mV;5425.0|243;5438 mV;5438.0|244;5450 mV;5450.0|245;5462 mV;5462.0|246;5475 mV;5475.0|247;5488 mV;5488.0|248;5500 mV;5500.0|249;5512 mV;5512.0|250;5525 mV;5525.0|251;5538 mV;5538.0|252;5550 mV;5550.0|253;5562 mV;5562.0|254;5575 mV;5575.0|255;5588 mV;5588.0',
      min: 0, max: 255, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 19, key: 'VDBAT_OFFSET_HIGH', title: 'VDBAT regulation offset, high',
      group: 'Power regulation', help: 'Sets the Vdbat high offset. When the PRL is set to PowerRegulationLoop_ExternalVbat, or to PowerRegulationLoop_Internal, the device will request power levels from the Poller in such a way that the VddC voltage is maintained within a dynamic range defined relative to the battery voltage. Specifically, the target range for VddC is between Vdbat + VdBatOffsetLow and Vdbat + VdBatOffsetHigh. The device continuously adjusts its power requests to maintain VddC within these bounds, ensuring stable operation aligned with the current battery conditions.',
      kind: OemKind.enumValue, optionSpec: '0;0 mV;0.0|1;12 mV;12.0|2;25 mV;25.0|3;38 mV;38.0|4;50 mV;50.0|5;62 mV;62.0|6;75 mV;75.0|7;88 mV;88.0|8;100 mV;100.0|9;112 mV;112.0|10;125 mV;125.0|11;138 mV;138.0|12;150 mV;150.0|13;162 mV;162.0|14;175 mV;175.0|15;188 mV;188.0|16;200 mV;200.0|17;212 mV;212.0|18;225 mV;225.0|19;238 mV;238.0|20;250 mV;250.0|21;262 mV;262.0|22;275 mV;275.0|23;288 mV;288.0|24;300 mV;300.0|25;312 mV;312.0|26;325 mV;325.0|27;338 mV;338.0|28;350 mV;350.0|29;362 mV;362.0|30;375 mV;375.0|31;388 mV;388.0|32;400 mV;400.0|33;412 mV;412.0|34;425 mV;425.0|35;438 mV;438.0|36;450 mV;450.0|37;462 mV;462.0|38;475 mV;475.0|39;488 mV;488.0|40;500 mV;500.0|41;512 mV;512.0|42;525 mV;525.0|43;538 mV;538.0|44;550 mV;550.0|45;562 mV;562.0|46;575 mV;575.0|47;588 mV;588.0|48;600 mV;600.0|49;612 mV;612.0|50;625 mV;625.0|51;638 mV;638.0|52;650 mV;650.0|53;662 mV;662.0|54;675 mV;675.0|55;688 mV;688.0|56;700 mV;700.0|57;712 mV;712.0|58;725 mV;725.0|59;738 mV;738.0|60;750 mV;750.0|61;762 mV;762.0|62;775 mV;775.0|63;788 mV;788.0|64;800 mV;800.0|65;812 mV;812.0|66;825 mV;825.0|67;838 mV;838.0|68;850 mV;850.0|69;862 mV;862.0|70;875 mV;875.0|71;888 mV;888.0|72;900 mV;900.0|73;912 mV;912.0|74;925 mV;925.0|75;938 mV;938.0|76;950 mV;950.0|77;962 mV;962.0|78;975 mV;975.0|79;988 mV;988.0|80;1000 mV;1000.0|81;1012 mV;1012.0|82;1025 mV;1025.0|83;1038 mV;1038.0|84;1050 mV;1050.0|85;1062 mV;1062.0|86;1075 mV;1075.0|87;1088 mV;1088.0|88;1100 mV;1100.0|89;1112 mV;1112.0|90;1125 mV;1125.0|91;1138 mV;1138.0|92;1150 mV;1150.0|93;1162 mV;1162.0|94;1175 mV;1175.0|95;1188 mV;1188.0|96;1200 mV;1200.0|97;1212 mV;1212.0|98;1225 mV;1225.0|99;1238 mV;1238.0|100;1250 mV;1250.0|101;1262 mV;1262.0|102;1275 mV;1275.0|103;1288 mV;1288.0|104;1300 mV;1300.0|105;1312 mV;1312.0|106;1325 mV;1325.0|107;1338 mV;1338.0|108;1350 mV;1350.0|109;1362 mV;1362.0|110;1375 mV;1375.0|111;1388 mV;1388.0|112;1400 mV;1400.0|113;1412 mV;1412.0|114;1425 mV;1425.0|115;1438 mV;1438.0|116;1450 mV;1450.0|117;1462 mV;1462.0|118;1475 mV;1475.0|119;1488 mV;1488.0|120;1500 mV;1500.0|121;1512 mV;1512.0|122;1525 mV;1525.0|123;1538 mV;1538.0|124;1550 mV;1550.0|125;1562 mV;1562.0|126;1575 mV;1575.0|127;1588 mV;1588.0|128;1600 mV;1600.0|129;1612 mV;1612.0|130;1625 mV;1625.0|131;1638 mV;1638.0|132;1650 mV;1650.0|133;1662 mV;1662.0|134;1675 mV;1675.0|135;1688 mV;1688.0|136;1700 mV;1700.0|137;1712 mV;1712.0|138;1725 mV;1725.0|139;1738 mV;1738.0|140;1750 mV;1750.0|141;1762 mV;1762.0|142;1775 mV;1775.0|143;1788 mV;1788.0|144;1800 mV;1800.0|145;1812 mV;1812.0|146;1825 mV;1825.0|147;1838 mV;1838.0|148;1850 mV;1850.0|149;1862 mV;1862.0|150;1875 mV;1875.0|151;1888 mV;1888.0|152;1900 mV;1900.0|153;1912 mV;1912.0|154;1925 mV;1925.0|155;1938 mV;1938.0|156;1950 mV;1950.0|157;1962 mV;1962.0|158;1975 mV;1975.0|159;1988 mV;1988.0|160;2000 mV;2000.0|161;2012 mV;2012.0|162;2025 mV;2025.0|163;2038 mV;2038.0|164;2050 mV;2050.0|165;2062 mV;2062.0|166;2075 mV;2075.0|167;2088 mV;2088.0|168;2100 mV;2100.0|169;2112 mV;2112.0|170;2125 mV;2125.0|171;2138 mV;2138.0|172;2150 mV;2150.0|173;2162 mV;2162.0|174;2175 mV;2175.0|175;2188 mV;2188.0|176;2200 mV;2200.0|177;2212 mV;2212.0|178;2225 mV;2225.0|179;2238 mV;2238.0|180;2250 mV;2250.0|181;2262 mV;2262.0|182;2275 mV;2275.0|183;2288 mV;2288.0|184;2300 mV;2300.0|185;2312 mV;2312.0|186;2325 mV;2325.0|187;2338 mV;2338.0|188;2350 mV;2350.0|189;2362 mV;2362.0|190;2375 mV;2375.0|191;2388 mV;2388.0|192;2400 mV;2400.0|193;2412 mV;2412.0|194;2425 mV;2425.0|195;2438 mV;2438.0|196;2450 mV;2450.0|197;2462 mV;2462.0|198;2475 mV;2475.0|199;2488 mV;2488.0|200;2500 mV;2500.0|201;2512 mV;2512.0|202;2525 mV;2525.0|203;2538 mV;2538.0|204;2550 mV;2550.0|205;2562 mV;2562.0|206;2575 mV;2575.0|207;2588 mV;2588.0|208;2600 mV;2600.0|209;2612 mV;2612.0|210;2625 mV;2625.0|211;2638 mV;2638.0|212;2650 mV;2650.0|213;2662 mV;2662.0|214;2675 mV;2675.0|215;2688 mV;2688.0|216;2700 mV;2700.0|217;2712 mV;2712.0|218;2725 mV;2725.0|219;2738 mV;2738.0|220;2750 mV;2750.0|221;2762 mV;2762.0|222;2775 mV;2775.0|223;2788 mV;2788.0|224;2800 mV;2800.0|225;2812 mV;2812.0|226;2825 mV;2825.0|227;2838 mV;2838.0|228;2850 mV;2850.0|229;2862 mV;2862.0|230;2875 mV;2875.0|231;2888 mV;2888.0|232;2900 mV;2900.0|233;2912 mV;2912.0|234;2925 mV;2925.0|235;2938 mV;2938.0|236;2950 mV;2950.0|237;2962 mV;2962.0|238;2975 mV;2975.0|239;2988 mV;2988.0|240;3000 mV;3000.0|241;3012 mV;3012.0|242;3025 mV;3025.0|243;3038 mV;3038.0|244;3050 mV;3050.0|245;3062 mV;3062.0|246;3075 mV;3075.0|247;3088 mV;3088.0|248;3100 mV;3100.0|249;3112 mV;3112.0|250;3125 mV;3125.0|251;3138 mV;3138.0|252;3150 mV;3150.0|253;3162 mV;3162.0|254;3175 mV;3175.0|255;3188 mV;3188.0',
      min: 0, max: 255, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 20, key: 'VDBAT_OFFSET_LOW', title: 'VDBAT regulation offset, low',
      group: 'Power regulation', help: 'Sets the Vdbat low offset. When the PRL is set to PowerRegulationLoop_ExternalVbat, or to PowerRegulationLoop_Internal, the device will request power levels from the Poller in such a way that the VddC voltage is maintained within a dynamic range defined relative to the battery voltage. Specifically, the target range for VddC is between Vdbat + VdBatOffsetLow and Vdbat + VdBatOffsetHigh. The device continuously adjusts its power requests to maintain VddC within these bounds, ensuring stable operation aligned with the current battery conditions.',
      kind: OemKind.enumValue, optionSpec: '0;0 mV;0.0|1;12 mV;12.0|2;25 mV;25.0|3;38 mV;38.0|4;50 mV;50.0|5;62 mV;62.0|6;75 mV;75.0|7;88 mV;88.0|8;100 mV;100.0|9;112 mV;112.0|10;125 mV;125.0|11;138 mV;138.0|12;150 mV;150.0|13;162 mV;162.0|14;175 mV;175.0|15;188 mV;188.0|16;200 mV;200.0|17;212 mV;212.0|18;225 mV;225.0|19;238 mV;238.0|20;250 mV;250.0|21;262 mV;262.0|22;275 mV;275.0|23;288 mV;288.0|24;300 mV;300.0|25;312 mV;312.0|26;325 mV;325.0|27;338 mV;338.0|28;350 mV;350.0|29;362 mV;362.0|30;375 mV;375.0|31;388 mV;388.0|32;400 mV;400.0|33;412 mV;412.0|34;425 mV;425.0|35;438 mV;438.0|36;450 mV;450.0|37;462 mV;462.0|38;475 mV;475.0|39;488 mV;488.0|40;500 mV;500.0|41;512 mV;512.0|42;525 mV;525.0|43;538 mV;538.0|44;550 mV;550.0|45;562 mV;562.0|46;575 mV;575.0|47;588 mV;588.0|48;600 mV;600.0|49;612 mV;612.0|50;625 mV;625.0|51;638 mV;638.0|52;650 mV;650.0|53;662 mV;662.0|54;675 mV;675.0|55;688 mV;688.0|56;700 mV;700.0|57;712 mV;712.0|58;725 mV;725.0|59;738 mV;738.0|60;750 mV;750.0|61;762 mV;762.0|62;775 mV;775.0|63;788 mV;788.0|64;800 mV;800.0|65;812 mV;812.0|66;825 mV;825.0|67;838 mV;838.0|68;850 mV;850.0|69;862 mV;862.0|70;875 mV;875.0|71;888 mV;888.0|72;900 mV;900.0|73;912 mV;912.0|74;925 mV;925.0|75;938 mV;938.0|76;950 mV;950.0|77;962 mV;962.0|78;975 mV;975.0|79;988 mV;988.0|80;1000 mV;1000.0|81;1012 mV;1012.0|82;1025 mV;1025.0|83;1038 mV;1038.0|84;1050 mV;1050.0|85;1062 mV;1062.0|86;1075 mV;1075.0|87;1088 mV;1088.0|88;1100 mV;1100.0|89;1112 mV;1112.0|90;1125 mV;1125.0|91;1138 mV;1138.0|92;1150 mV;1150.0|93;1162 mV;1162.0|94;1175 mV;1175.0|95;1188 mV;1188.0|96;1200 mV;1200.0|97;1212 mV;1212.0|98;1225 mV;1225.0|99;1238 mV;1238.0|100;1250 mV;1250.0|101;1262 mV;1262.0|102;1275 mV;1275.0|103;1288 mV;1288.0|104;1300 mV;1300.0|105;1312 mV;1312.0|106;1325 mV;1325.0|107;1338 mV;1338.0|108;1350 mV;1350.0|109;1362 mV;1362.0|110;1375 mV;1375.0|111;1388 mV;1388.0|112;1400 mV;1400.0|113;1412 mV;1412.0|114;1425 mV;1425.0|115;1438 mV;1438.0|116;1450 mV;1450.0|117;1462 mV;1462.0|118;1475 mV;1475.0|119;1488 mV;1488.0|120;1500 mV;1500.0|121;1512 mV;1512.0|122;1525 mV;1525.0|123;1538 mV;1538.0|124;1550 mV;1550.0|125;1562 mV;1562.0|126;1575 mV;1575.0|127;1588 mV;1588.0|128;1600 mV;1600.0|129;1612 mV;1612.0|130;1625 mV;1625.0|131;1638 mV;1638.0|132;1650 mV;1650.0|133;1662 mV;1662.0|134;1675 mV;1675.0|135;1688 mV;1688.0|136;1700 mV;1700.0|137;1712 mV;1712.0|138;1725 mV;1725.0|139;1738 mV;1738.0|140;1750 mV;1750.0|141;1762 mV;1762.0|142;1775 mV;1775.0|143;1788 mV;1788.0|144;1800 mV;1800.0|145;1812 mV;1812.0|146;1825 mV;1825.0|147;1838 mV;1838.0|148;1850 mV;1850.0|149;1862 mV;1862.0|150;1875 mV;1875.0|151;1888 mV;1888.0|152;1900 mV;1900.0|153;1912 mV;1912.0|154;1925 mV;1925.0|155;1938 mV;1938.0|156;1950 mV;1950.0|157;1962 mV;1962.0|158;1975 mV;1975.0|159;1988 mV;1988.0|160;2000 mV;2000.0|161;2012 mV;2012.0|162;2025 mV;2025.0|163;2038 mV;2038.0|164;2050 mV;2050.0|165;2062 mV;2062.0|166;2075 mV;2075.0|167;2088 mV;2088.0|168;2100 mV;2100.0|169;2112 mV;2112.0|170;2125 mV;2125.0|171;2138 mV;2138.0|172;2150 mV;2150.0|173;2162 mV;2162.0|174;2175 mV;2175.0|175;2188 mV;2188.0|176;2200 mV;2200.0|177;2212 mV;2212.0|178;2225 mV;2225.0|179;2238 mV;2238.0|180;2250 mV;2250.0|181;2262 mV;2262.0|182;2275 mV;2275.0|183;2288 mV;2288.0|184;2300 mV;2300.0|185;2312 mV;2312.0|186;2325 mV;2325.0|187;2338 mV;2338.0|188;2350 mV;2350.0|189;2362 mV;2362.0|190;2375 mV;2375.0|191;2388 mV;2388.0|192;2400 mV;2400.0|193;2412 mV;2412.0|194;2425 mV;2425.0|195;2438 mV;2438.0|196;2450 mV;2450.0|197;2462 mV;2462.0|198;2475 mV;2475.0|199;2488 mV;2488.0|200;2500 mV;2500.0|201;2512 mV;2512.0|202;2525 mV;2525.0|203;2538 mV;2538.0|204;2550 mV;2550.0|205;2562 mV;2562.0|206;2575 mV;2575.0|207;2588 mV;2588.0|208;2600 mV;2600.0|209;2612 mV;2612.0|210;2625 mV;2625.0|211;2638 mV;2638.0|212;2650 mV;2650.0|213;2662 mV;2662.0|214;2675 mV;2675.0|215;2688 mV;2688.0|216;2700 mV;2700.0|217;2712 mV;2712.0|218;2725 mV;2725.0|219;2738 mV;2738.0|220;2750 mV;2750.0|221;2762 mV;2762.0|222;2775 mV;2775.0|223;2788 mV;2788.0|224;2800 mV;2800.0|225;2812 mV;2812.0|226;2825 mV;2825.0|227;2838 mV;2838.0|228;2850 mV;2850.0|229;2862 mV;2862.0|230;2875 mV;2875.0|231;2888 mV;2888.0|232;2900 mV;2900.0|233;2912 mV;2912.0|234;2925 mV;2925.0|235;2938 mV;2938.0|236;2950 mV;2950.0|237;2962 mV;2962.0|238;2975 mV;2975.0|239;2988 mV;2988.0|240;3000 mV;3000.0|241;3012 mV;3012.0|242;3025 mV;3025.0|243;3038 mV;3038.0|244;3050 mV;3050.0|245;3062 mV;3062.0|246;3075 mV;3075.0|247;3088 mV;3088.0|248;3100 mV;3100.0|249;3112 mV;3112.0|250;3125 mV;3125.0|251;3138 mV;3138.0|252;3150 mV;3150.0|253;3162 mV;3162.0|254;3175 mV;3175.0|255;3188 mV;3188.0',
      min: 0, max: 255, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 21, key: 'WPT_DURATION_HOST', title: 'WPT duration (host)',
      group: 'Wireless power transfer', help: 'Sets the duration of the host WPT cycle. With force == false, it is used for all cases where no other WPT cycle duration is applicable. With force == true, it is additionally used for TCM, CCM and CVM WPT cycles as well. For this case, the explicit durations for TCM, CCM and CVM are ignored.',
      kind: OemKind.enumValue, optionSpec: '0;8 ms;|1;16 ms;|2;32 ms;|3;64 ms;|4;128 ms;|5;256 ms;|6;512 ms;|7;1024 ms;|8;2048 ms;|9;4096 ms;|10;8192 ms;|11;16384 ms;|12;32768 ms;|13;65536 ms (~1.1 min.);|14;131072 ms (~2.2 min.);|15;262144 ms (~4.4 min.);|16;524288 ms (~8.7 min.);|17;1048576 ms (~17.5 min.);|18;2097152 ms (~35 min.);|19;4194304 ms (~70 min.);',
      min: 0, max: 19, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 22, key: 'WPT_DURATION_ADJ', title: 'WPT duration (adjustment)',
      group: 'Wireless power transfer', help: 'Sets the duration of an adjustment WPT cycle.',
      kind: OemKind.enumValue, optionSpec: '0;8 ms;|1;16 ms;|2;32 ms;|3;64 ms;|4;128 ms;|5;256 ms;|6;512 ms;|7;1024 ms;|8;2048 ms;|9;4096 ms;|10;8192 ms;|11;16384 ms;|12;32768 ms;|13;65536 ms (~1.1 min.);|14;131072 ms (~2.2 min.);|15;262144 ms (~4.4 min.);|16;524288 ms (~8.7 min.);|17;1048576 ms (~17.5 min.);|18;2097152 ms (~35 min.);|19;4194304 ms (~70 min.);',
      min: 0, max: 19, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 23, key: 'WPT_DURATION_TCM', title: 'WPT duration (trickle charge)',
      group: 'Wireless power transfer', help: 'Sets the duration of a trickle charging WPT cycle.',
      kind: OemKind.enumValue, optionSpec: '0;8 ms;|1;16 ms;|2;32 ms;|3;64 ms;|4;128 ms;|5;256 ms;|6;512 ms;|7;1024 ms;|8;2048 ms;|9;4096 ms;|10;8192 ms;|11;16384 ms;|12;32768 ms;|13;65536 ms (~1.1 min.);|14;131072 ms (~2.2 min.);|15;262144 ms (~4.4 min.);|16;524288 ms (~8.7 min.);|17;1048576 ms (~17.5 min.);|18;2097152 ms (~35 min.);|19;4194304 ms (~70 min.);',
      min: 0, max: 19, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 24, key: 'WPT_DURATION_CCM', title: 'WPT duration (constant current)',
      group: 'Wireless power transfer', help: 'Sets the duration of a constant current charging WPT cycle.',
      kind: OemKind.enumValue, optionSpec: '0;8 ms;|1;16 ms;|2;32 ms;|3;64 ms;|4;128 ms;|5;256 ms;|6;512 ms;|7;1024 ms;|8;2048 ms;|9;4096 ms;|10;8192 ms;|11;16384 ms;|12;32768 ms;|13;65536 ms (~1.1 min.);|14;131072 ms (~2.2 min.);|15;262144 ms (~4.4 min.);|16;524288 ms (~8.7 min.);|17;1048576 ms (~17.5 min.);|18;2097152 ms (~35 min.);|19;4194304 ms (~70 min.);',
      min: 0, max: 19, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 25, key: 'WPT_DURATION_CVM', title: 'WPT duration (constant voltage)',
      group: 'Wireless power transfer', help: 'Sets the duration of a constant voltage charging WPT cycle.',
      kind: OemKind.enumValue, optionSpec: '0;8 ms;|1;16 ms;|2;32 ms;|3;64 ms;|4;128 ms;|5;256 ms;|6;512 ms;|7;1024 ms;|8;2048 ms;|9;4096 ms;|10;8192 ms;|11;16384 ms;|12;32768 ms;|13;65536 ms (~1.1 min.);|14;131072 ms (~2.2 min.);|15;262144 ms (~4.4 min.);|16;524288 ms (~8.7 min.);|17;1048576 ms (~17.5 min.);|18;2097152 ms (~35 min.);|19;4194304 ms (~70 min.);',
      min: 0, max: 19, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 26, key: 'TCM_TIMEOUT', title: 'Trickle charge timeout',
      group: 'Battery protection', help: 'Sets the timeout of the trickle charging phase. If the charging phase takes longer than the set timeout, charging will be terminated.',
      kind: OemKind.number, optionSpec: '',
      min: 0, max: 255, unit: 'x 65.5 s (0 = off)', hex: false, risky: false,
    ),
    OemParam(
      id: 27, key: 'CCM_TIMEOUT', title: 'Constant current timeout',
      group: 'Battery protection', help: 'Sets the timeout of the constant current charging phase. If the charging phase takes longer than the set timeout, charging will be terminated.',
      kind: OemKind.number, optionSpec: '',
      min: 0, max: 255, unit: 'x 65.5 s (0 = off)', hex: false, risky: false,
    ),
    OemParam(
      id: 28, key: 'CVM_TIMEOUT', title: 'Constant voltage timeout',
      group: 'Battery protection', help: 'Sets the timeout of the constant voltage charging phase. If the charging phase takes longer than the set timeout, charging will be terminated.',
      kind: OemKind.number, optionSpec: '',
      min: 0, max: 255, unit: 'x 65.5 s (0 = off)', hex: false, risky: false,
    ),
    OemParam(
      id: 29, key: 'GPIO1_CONFIG', title: 'GPIO1 function',
      group: 'Host interface', help: 'Configures the functionality of GPIO1.',
      kind: OemKind.enumValue, optionSpec: '5;WLC-P controlled (out);',
      min: 5, max: 5, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 30, key: 'GPIO0_CONFIG', title: 'GPIO0 function',
      group: 'Host interface', help: 'Configures the functionality of GPIO0.',
      kind: OemKind.enumValue, optionSpec: '5;WLC-P controlled (out);',
      min: 5, max: 5, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 31, key: 'CAP_WT_INT', title: 'WPT interval in the CAP record',
      group: 'Wireless power transfer', help: 'Defines the CAP_WT_INT reported to the Poller in the capability record.',
      kind: OemKind.enumValue, optionSpec: '0;8 ms;|1;16 ms;|2;32 ms;|3;64 ms;|4;128 ms;|5;256 ms;|6;512 ms;|7;1024 ms;|8;2048 ms;|9;4096 ms;|10;8192 ms;|11;16384 ms;|12;32768 ms;|13;65536 ms (~1.1 min.);|14;131072 ms (~2.2 min.);|15;262144 ms (~4.4 min.);|16;524288 ms (~8.7 min.);|17;1048576 ms (~17.5 min.);|18;2097152 ms (~35 min.);|19;4194304 ms (~70 min.);',
      min: 0, max: 19, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 32, key: 'I2C_ADDRESS', title: 'I2C address',
      group: 'Host interface', help: 'Defines I2C address of the RRQ36031.',
      kind: OemKind.number, optionSpec: '',
      min: 75, max: 75, unit: '7-bit address', hex: true, risky: false,
    ),
    OemParam(
      id: 33, key: 'IRQ_POLARITY', title: 'IRQ pin polarity',
      group: 'Host interface', help: 'Sets the polarity of the RRQ36031\'s IRQ line.',
      kind: OemKind.enumValue, optionSpec: '0;Interrupt pin configured to active HIGH;',
      min: 0, max: 0, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 34, key: 'SM_MIN_PRESS_TIME', title: 'Shipping mode wake-up press time',
      group: 'Supply outputs', help: 'Sets the minimum press time of the SM button to get the system out of shipping mode. If no button is connected to the SM-Pin use a FET pulling down the SM-Pin to wake-up the device.',
      kind: OemKind.enumValue, optionSpec: '0;SM button minimum press time of 5 seconds;|1;SM button minimum press time of 10 seconds;|2;SM button minimum press time of 15 seconds;|3;SM button minimum press time of 20 seconds;',
      min: 0, max: 3, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 35, key: 'VDMCU_MODE', title: 'VDMCU mode',
      group: 'Supply outputs', help: 'Sets the mode of VdMcu which can either be an output (1.8V or 3.3V) or an input to supply the RRQ36031\'s GPIO pads.',
      kind: OemKind.enumValue, optionSpec: '0;VdMcu is configured to be supplied externally;|1;VdMcu is configured to output 1.8 V;1800.0|2;VdMcu is configured to output 3.3 V;3300.0',
      min: 0, max: 2, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 36, key: 'VDMCU_LDO', title: 'VDMCU LDO',
      group: 'Supply outputs', help: 'Defines which of the two internal LDOs will be used to supply VdMcu. The low power LDO can deliver up to 5mA supply current, whereas the high power LDO can deliver up to 50mA. This setting will also influence the standby current.',
      kind: OemKind.enumValue, optionSpec: '0;low power LDO;|1;high power LDO;',
      min: 0, max: 1, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 37, key: 'VDSYS_ENABLE', title: 'VDSYS output',
      group: 'Supply outputs', help: 'Defines if the VdSys pin will be enabled by the RRQ36031.',
      kind: OemKind.boolValue, optionSpec: '1;Enabled;',
      min: 1, max: 1, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 38, key: 'VDSYS_GUARD_TIME', title: 'VDSYS guard time',
      group: 'Supply outputs', help: 'Guard time before activating the VdSys high-power switch measured in milliseconds. The parameter can be calculated as follows: VdSysHpGt = Roundup(C/5) where C is the load capacitance on VdSys in uF.',
      kind: OemKind.number, optionSpec: '',
      min: 0, max: 255, unit: 'ms', hex: false, risky: false,
    ),
    OemParam(
      id: 39, key: 'RESISTIVE_MOD', title: 'Modulation resistor (modulating)',
      group: 'NFC antenna', help: 'Defines the modulation resistor value for NFC communication, when modulating. This setting influences the antenna system\'s Q-factor. Note: ResistiveMod must be different from ResistiveSet for the NFC-Reader/Poller to see the modulation!',
      kind: OemKind.enumValue, optionSpec: '0;Modulation resistor disabled (Open);|1;170 Ohm;|2;85 Ohm;|3;57 Ohm;|4;43 Ohm;|5;34 Ohm;|6;27 Ohm;|7;24 Ohm;|8;21 Ohm;|9;19 Ohm;|10;17 Ohm;|11;15 Ohm;|12;14 Ohm;|13;13 Ohm;|14;12 Ohm;|15;11 Ohm;',
      min: 0, max: 15, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 40, key: 'RESISTIVE_SET', title: 'Modulation resistor (idle)',
      group: 'NFC antenna', help: 'Defines the modulation resistor value for NFC communication, when idle. This setting influences the antenna system\'s Q-factor. Note: ResistiveSet must be different from ResistiveMod for the NFC-Reader/Poller to see the modulation!',
      kind: OemKind.enumValue, optionSpec: '0;Modulation resistor disabled (Open);|1;170 Ohm;|2;85 Ohm;|3;57 Ohm;|4;43 Ohm;|5;34 Ohm;|6;27 Ohm;|7;24 Ohm;|8;21 Ohm;|9;19 Ohm;|10;17 Ohm;|11;15 Ohm;|12;14 Ohm;|13;13 Ohm;|14;12 Ohm;|15;11 Ohm;',
      min: 0, max: 15, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 41, key: 'WLC_CAP_RECORD', title: 'WLC_CAP NDEF record',
      group: 'Wireless power transfer', help: 'Enable/Disable the WLC_CAP NDEF record. If disabled, the Poller will not detect the RRQ36031 as WLC Listener anymore.',
      kind: OemKind.boolValue, optionSpec: '0;Disabled;|1;Enabled;',
      min: 0, max: 1, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 42, key: 'WPT_REQUEST_SELECT', title: 'WPT request source',
      group: 'Wireless power transfer', help: 'Configures the WPT request selection, please see \\ref RRQ36031_WptReqSel_t.',
      kind: OemKind.enumValue, optionSpec: '0;WPT Request controlled by internal battery charger;|1;WPT Request permanently disabled;|2;WPT Request permanently enabled;',
      min: 0, max: 2, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 43, key: 'IC_OVERPOWER_THRESHOLD', title: 'IC overpower threshold',
      group: 'Battery protection', help: 'The device integrates the current through the current limiter at 1ms intervals and triggers an ErrorStatus_IcOverpower if the integrated sum exceeds the IC_OVERPOWER_TH threshold.',
      kind: OemKind.number, optionSpec: '',
      min: 0, max: 65535, unit: '(0 = off)', hex: false, risky: false,
    ),
    OemParam(
      id: 44, key: 'NTC_THRESHOLD_OFFSET_HOT', title: 'NTC hot threshold offset',
      group: 'Temperature (NTC)', help: 'Sets the NTC HOT Threshold Offset Value for which the NTC Threshold is shifted from the initial value of +45C in 20 mV steps. Note: For a NTC thermistor with beta=4050K and R25=10kOhm this is equivalent to approximately +/-1.2C steps. e.g.: 20 mV -> -1.2C, -40 mV -> +2.4C.',
      kind: OemKind.enumValue, optionSpec: '0;0 mV;0.0|1;20 mV;20.0|2;40 mV;40.0|3;60 mV;60.0|13;-60 mV;-60.0|14;-40 mV;-40.0|15;-20 mV;-20.0',
      min: 0, max: 15, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 45, key: 'NTC_THRESHOLD_OFFSET_COLD', title: 'NTC cold threshold offset',
      group: 'Temperature (NTC)', help: 'Sets the NTC COLD Threshold Offset Value for which the NTC Threshold is shifted from the initial value of +10C in 10mV steps. Note: For a NTC thermistor with beta=4050K and R25=10kOhm this is equivalent to approximately +/-1.05C steps. e.g.: 10 mV -> -1.05C, -20 mV -> +2.1C.',
      kind: OemKind.enumValue, optionSpec: '0;0 mV;0.0|1;10 mV;10.0|2;20 mV;20.0|3;30 mV;30.0|13;-30 mV;-30.0|14;-20 mV;-20.0|15;-10 mV;-10.0',
      min: 0, max: 15, unit: '', hex: false, risky: false,
    ),
    OemParam(
      id: 46, key: 'CHARGING_DURING_COMM', title: 'Charge during NFC communication',
      group: 'Charging', help: 'Enables/disables charging while NFC communication is active. If disabled, charging is suspended while communication is ongoing.',
      kind: OemKind.boolValue, optionSpec: '0;Disabled;|1;Enabled;',
      min: 0, max: 1, unit: '', hex: false, risky: false,
    ),
  ];

  static final Map<int, OemParam> byId = {
    for (final p in params) p.id: p,
  };

  static List<String> get groups {
    final seen = <String>{};
    final result = <String>[];
    for (final p in params) {
      if (seen.add(p.group)) result.add(p.group);
    }
    return result;
  }
}
