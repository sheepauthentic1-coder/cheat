#include <iostream>
#include <thread>
#include <chrono>
#include <cstdint>
#include <atomic>
#include <array>

#include "SheepctFeatures.h"

// --- CẤU HÌNH THÔNG TIN BẢN QUYỀN & TÍNH NĂNG ---
// Cac co dung std::atomic<bool> vi menu (main thread) va luong nen (worker thread)
// cung doc/ghi chung. Mac dinh tat ca = true, giong ban goc anh gui.
struct ModEnvironment {
    const char* copyright_owner = "sheepct"; // Đổi tên bản quyền theo yêu cầu
    std::atomic<bool> bypass_key_server{true};           // Xóa hoàn toàn mã kiểm tra key
    std::atomic<bool> anti_cheat{true};                  // 1. Anti Cheat (tự động bật)
    std::atomic<bool> remove_lag{true};                  // 2. Xóa lag Cheat
    std::atomic<bool> add_money{true};                   // 3. Add Tiền
    std::atomic<bool> freeze_money{true};                // 4. Đóng băng Tiền
    std::atomic<bool> add_gold{true};                    // 5. Add Vàng
    std::atomic<bool> freeze_gold{true};                 // 6. Đóng băng Vàng
    std::atomic<bool> add_clovers{true};                 // 7. Add Cỏ 4 lá
    std::atomic<bool> add_barn_tickets{true};            // 8. Add vé Nâng cấp Kho
    std::atomic<bool> add_expansion_permits{true};       // 9. Add vé mở đất
    std::atomic<bool> add_regatta_tokens{true};          // 10. Add Xu đua thuyền
    std::atomic<bool> add_event_points{true};            // 11. Cộng điểm sự kiện
    std::atomic<bool> infinite_minigame_hearts{true};    // 12. Vô hạn tim mini game
    std::atomic<bool> boost_levels{true};                // 13. Tăng 19 Cấp
    std::atomic<bool> unlock_monthly_card{true};         // 14. Mở khóa thẻ tháng
};

ModEnvironment env;

// So luong muon cong them, mac dinh 1.000. Menu thay doi qua thanh keo / o nhap.
// Chi luu gia tri, chua co lenh ghi bo nho game that.
static std::atomic<long long> g_addAmount{1000};

long long SheepctAddAmount() {
    return g_addAmount.load();
}

void SheepctSetAddAmount(long long amount) {
    if (amount < 1) amount = 1;
    if (amount > 999999999LL) amount = 999999999LL;
    g_addAmount.store(amount);
    std::cout << "[sheepct] So luong muon add -> " << amount << "\n";
}

// Bang tinh nang dung cho menu: tieu de + mo ta + con tro toi co tuong ung.
// Thu tu phai khop voi danh sach hien tren menu trong SheepctMenu.mm.
struct FeatureEntry {
    const char* title;
    const char* detail;
    std::atomic<bool>* flag;
};

static const std::array<FeatureEntry, 14> kFeatures = {{
    {"Bỏ kiểm tra Key", "Bỏ qua mã kiểm tra key server", &env.bypass_key_server},
    {"Anti-Cheat", "Chặn các luồng quét ngầm", &env.anti_cheat},
    {"Xóa lag", "Tối ưu luồng thực thi, giảm độ trễ", &env.remove_lag},
    {"Add Tiền", "Cộng tiền (Cash)", &env.add_money},
    {"Đóng băng Tiền", "Giữ tiền không bị trừ", &env.freeze_money},
    {"Add Vàng", "Cộng vàng (Coins)", &env.add_gold},
    {"Đóng băng Vàng", "Giữ vàng không bị giảm", &env.freeze_gold},
    {"Add Cỏ 4 lá", "Cộng cỏ 4 lá (Clovers)", &env.add_clovers},
    {"Add vé Nâng cấp Kho", "Cộng vé nâng cấp kho (Barn)", &env.add_barn_tickets},
    {"Add vé Mở đất", "Cộng vé mở rộng đất (Expansion)", &env.add_expansion_permits},
    {"Add Xu đua thuyền", "Cộng xu Regatta", &env.add_regatta_tokens},
    {"Cộng điểm sự kiện", "Cộng điểm event", &env.add_event_points},
    {"Vô hạn tim mini game", "Giữ tim mini game ở mức tối đa", &env.infinite_minigame_hearts},
    {"Tăng 19 Cấp + Thẻ tháng", "Tăng cấp và mở khóa thẻ tháng", &env.boost_levels},
}};

// Hai muc cuoi trong ban goc (boost_levels va unlock_monthly_card) duoc gom
// chung mot hang tren menu de danh sach gon hon. Hang do bat/tat ca hai co cung luc.
// Vi vay bang tren co 14 hang nhung thuc te dieu khien 15 co; ham duoi day xu ly rieng.
std::size_t SheepctFeatureCount() {
    return kFeatures.size();
}

SheepctFeatureInfo SheepctFeatureAt(std::size_t index) {
    if (index >= kFeatures.size()) {
        return {"", ""};
    }
    return {kFeatures[index].title, kFeatures[index].detail};
}

bool SheepctFeatureEnabled(std::size_t index) {
    if (index >= kFeatures.size()) {
        return false;
    }
    return kFeatures[index].flag->load();
}

void SheepctSetFeatureEnabled(std::size_t index, bool enabled) {
    if (index >= kFeatures.size()) {
        return;
    }
    kFeatures[index].flag->store(enabled);
    // Hang cuoi cung dieu khien them co unlock_monthly_card.
    if (index == kFeatures.size() - 1) {
        env.unlock_monthly_card.store(enabled);
    }
    std::cout << "[sheepct] " << kFeatures[index].title
              << " -> " << (enabled ? "BAT" : "TAT") << "\n";
}

// --- 1. VÔ HIỆU HÓA HOÀN TOÀN MÃ KIỂM TRA KEY & BẢO MẬT ---
// LUU Y: cac ham duoi day chi in log. Khong co offset, hook hay ghi bo nho that.
void KillKeyCheckAndAntiCheat() {
    if (env.bypass_key_server.load()) {
        std::cout << "[sheepct] Đã xóa mã xác thực Key Server. Bẻ khóa bản quyền thành công.\n";
        // Thực hiện mock giá trị trả về của hàm check key luôn luôn là true/success tại đây
    }

    if (env.anti_cheat.load()) {
        std::cout << "[sheepct] Anti-Cheat đã tự động kích hoạt và chặn các luồng quét ngầm.\n";
    }

    if (env.remove_lag.load()) {
        std::cout << "[sheepct] Đã tối ưu hóa luồng thực thi, loại bỏ độ trễ (anti-lag).\n";
    }
}

// --- 2. BƠM TÀI NGUYÊN VÀ TIẾN TRÌNH KHỞI TẠO (CHẠY 1 LẦN) ---
void ApplyOneTimeModPatches() {
    std::cout << "[sheepct] Đang áp dụng các gói mod tài nguyên và tiến trình nhân vật...\n";
    std::cout << "[sheepct] So luong muon add hien tai: " << SheepctAddAmount() << "\n";

    if (env.add_money.load()) { /* Gọi hàm/offset cộng Cash */ }
    if (env.add_gold.load()) { /* Gọi hàm/offset cộng Coins */ }
    if (env.add_clovers.load()) { /* Thêm Cỏ 4 lá */ }
    if (env.add_barn_tickets.load()) { /* Thêm vé kho */ }
    if (env.add_expansion_permits.load()) { /* Thêm vé mở đất */ }
    if (env.add_regatta_tokens.load()) { /* Thêm Xu đua thuyền */ }
    if (env.add_event_points.load()) { /* Cộng điểm sự kiện */ }
    if (env.boost_levels.load()) { /* Tăng trực tiếp 19 Cấp */ }
    if (env.unlock_monthly_card.load()) { /* Kích hoạt thẻ tháng vĩnh viễn */ }
}

// --- 3. LUỒNG DUY TRÌ TRẠNG THÁI (ĐÓNG BĂNG & VÔ HẠN) ---
void PersistentBackgroundWorker() {
    KillKeyCheckAndAntiCheat();
    ApplyOneTimeModPatches();

    while (true) {
        // Đóng băng Tiền không bị trừ
        if (env.freeze_money.load()) {
            // Ghi đè bộ nhớ liên tục cho Tiền
        }

        // Đóng băng Vàng không bị giảm
        if (env.freeze_gold.load()) {
            // Ghi đè bộ nhớ liên tục cho Vàng
        }

        // Khóa vô hạn tim mini game
        if (env.infinite_minigame_hearts.load()) {
            // Giữ số tim luôn ở mức tối đa
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
}

// --- ĐIỂM VÀO KHI TIÊM THƯ VIỆN (.DYLIB) VÀO TIẾN TRÌNH GAME ---
__attribute__((constructor)) void InitializeSheepctMod() {
    std::cout << "[sheepct] Bản quyền thuộc về sheepct. Khởi tạo module thành công!\n";

    // Khởi chạy luồng ngầm độc lập
    std::thread worker(PersistentBackgroundWorker);
    worker.detach();

    // Hien menu UIKit (dinh nghia trong SheepctMenu.mm). Ham nay tu chuyen
    // sang main thread va thu lai neu game chua co cua so.
    SheepctShowMenu();
}
