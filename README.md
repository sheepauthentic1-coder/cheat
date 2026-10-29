# sheepct mod — goi build

## Co gi trong nay

- `mod.cpp`: code goc anh gui, giu nguyen logic goc (chi in log, cho trong
  o cho can thiep game), chi doi cac co sang `std::atomic<bool>` de menu
  va luong nen cung doc/ghi an toan, va goi hien menu khi khoi tao.
- `SheepctFeatures.h`: danh sach tinh nang dung chung giua `mod.cpp` va menu.
- `SheepctMenu.mm`: menu UIKit chi tiet (xem muc Menu ben duoi).
- `build_ios.sh`: script build `.dylib` arm64 cho iOS, chay tren macOS co Xcode.
- `.github/workflows/build-ios.yml`: workflow GitHub Actions, build tren
  may Mac ao cua GitHub, khong can Mac that.

## Menu

Sau khi nap `.dylib` vao game:

- Mot nut tron chu "S" hien noi tren man hinh. Keo nut de doi vi tri,
  cham nhe vao nut de mo / dong bang menu. Cham ra ngoai bang menu thi
  game ben duoi van nhan cham nhu binh thuong.
- Bang menu co tieu de `sheepct`, dong trang thai "Dang bat: X/14",
  nut dong "X", va danh sach cuon duoc gom 14 hang, moi hang la mot
  tinh nang kem mo ta ngan va mot cong tac `UISwitch`.
- Chan bang co 2 nut "Bat tat ca" va "Tat tat ca", kem ghi chu gioi han.
- Hang cuoi cung gom chung "Tang 19 Cap" va "Mo khoa the thang" vi
  ca hai deu nam trong nhom cap/the trong code goc.

## So luong muon add (ban 2)

Phan tren cung cua bang menu la "SO LUONG MUON ADD", ap dung chung cho
cac muc Add (tien, vang, co 4 la, ve, xu, diem):

- Thanh keo (slider): keo tu 1 den 100.000, lam tron theo buoc 10.
- Nut - / + (stepper): moi lan nhan doi 100, toi da 1.000.000.
- O nhap so: go so chinh xac toi da 999.999.999, ban phim so.
- Nut mau: 100, 1K, 10K, 100K, 1M.

Mac dinh la 1.000. Gia tri chi luu trong mod (`SheepctAddAmount()`).

## Menu muot / khong chan game (ban 2)

- Mo/dong bang co animation spring, nut S co hieu ung nhan nho khi cham,
  keo xong nut tu dinh vao mep gan nhat.
- Cua so menu khong tro thanh key window, cham o ngoai bang menu xuyen
  xuong game, nen popup cua game (vi du man hinh xac thuc) van nhan
  cham / ban phim binh thuong. Neu popup bi nut S che, keo nut S ra
  cho khac, hoac bam X de dong bang menu.
- Man hinh xac thuc cua game van phai lam xong trong game, menu khong
  tu dien thong tin do thay anh.

GIOI HAN: cong tac va so luong chi doi co / gia tri trong `ModEnvironment`.
Phan ap dung that (offset, hook, ghi bo nho game) KHONG co trong ban nay,
nen bat cong tac cung chua lam tien/vang trong game thay doi. Menu chi la
giao dien + co + so luong.

## Tai sao khong co san file .dylib chay duoc tren iPhone?

May build o day la Linux x86_64, khong co Xcode, khong co iPhoneOS SDK,
khong co trinh lien ket Mach-O cua Apple. Vi vay khong the dong goi
thanh file `.dylib` Mach-O arm64 that de nap vao game tren iOS tu day.

File `.so` dang ELF build thu tren Linux chi de kiem tra code bien dich
duoc, khong nap duoc tren iOS, nen khong gui kem de tranh nham lan.

## Da kiem tra tren Linux

Lenh:

```
g++ -std=c++17 -Wall -fPIC -shared mod.cpp -o sheepct_test.so -pthread
```

Ket qua: bien dich sach, khong warning. Nap thu bang `dlopen` thi
`constructor` chay, thread nen chay va in dung 5 dong log `[sheepct]...`,
sau do vong lap khong lam gi them (dung nhu phan tich truoc do: cac cho
can thiep game dang la comment trong).

## Build bang GitHub Actions (khong can Mac that)

Cau truc repo tren GitHub:

```
mod.cpp
.github/workflows/build-ios.yml
```

Cac buoc:

1. Tao repo moi tren GitHub, up 2 file tren len, giu dung duong dan.
2. Vao tab Actions cua repo, cho workflow `Build iOS dylib` chay xong.
   Neu chua chay, bam `Run workflow`.
3. Vao lan chay vua xong, keo xuong muc Artifacts, tai
   `sheepct-dylib`, giai nen se co file `sheepct.dylib`.

Luu y: file tren GitHub chi la noi luu code. May build that su la
runner macOS cua GitHub Actions, khong phai may Linux cua Muse.
Muse khong tu truy cap / build truc tiep tu repo cua anh neu anh
khong dua quyen truy cap, va cung khong can thiet: cu push len la
Actions tu chay.

## Build tren Mac

```bash
cd sheepct-mod
chmod +x build_ios.sh
./build_ios.sh
```

Ket qua mong doi: file `sheepct.dylib`, `file` bao Mach-O 64-bit arm64.

## Ky vong khi test

Code nay hien tai chi in log, khong co offset / ghi bo nho that, nen
khi nap vao game anh se khong thay tien, vang hay tinh nang nao doi.
Neu khong thay gi thay doi trong game thi do la dung voi code hien tai,
khong phai loi build. Tren iOS, `std::cout` cung co the khong hien
trong console nhu tren Linux.
