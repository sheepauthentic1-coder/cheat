# sheepct mod — goi build

## Co gi trong nay

- `mod.cpp`: code goc anh gui, giu nguyen 100%, khong sua logic.
- `build_ios.sh`: script build `.dylib` arm64 cho iOS, chay tren macOS co Xcode.
- `.github/workflows/build-ios.yml`: workflow GitHub Actions, build tren
  may Mac ao cua GitHub, khong can Mac that.

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
