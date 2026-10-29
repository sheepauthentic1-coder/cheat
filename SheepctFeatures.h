#pragma once

#include <cstddef>

// Danh sach tinh nang dung chung giua mod.cpp (logic/co) va SheepctMenu.mm (giao dien).
// Menu chi doc/ghi cac co nay. Cac ham ap dung that (offset, hook, ghi bo nho game)
// KHONG co trong ban nay: phan than ham trong mod.cpp chi in log / de cho trong.
struct SheepctFeatureInfo {
    const char* title;   // Ten hien tren menu, tieng Viet.
    const char* detail;  // Mo ta ngan hien duoi ten.
};

std::size_t SheepctFeatureCount();
SheepctFeatureInfo SheepctFeatureAt(std::size_t index);
bool SheepctFeatureEnabled(std::size_t index);
void SheepctSetFeatureEnabled(std::size_t index, bool enabled);

// Hien menu UIKit. Duoc dinh nghia trong SheepctMenu.mm, goi tu constructor trong mod.cpp.
// Ham nay tu chuyen sang main queue va thu lai neu ung dung game chua co cua so.
void SheepctShowMenu();
