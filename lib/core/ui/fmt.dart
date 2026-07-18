/// Formatează un întreg cu separator de mii `.` (convenție românească),
/// ex. `1240` -> `1.240`.
String fmtThousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
