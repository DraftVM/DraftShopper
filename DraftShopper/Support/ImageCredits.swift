import Foundation

/// Attribution for bundled product photography. Every image is sourced from Wikimedia Commons
/// and released under CC0 1.0 (public domain dedication); attribution is a courtesy, not a requirement.
struct ImageCredit: Identifiable {
    let id: String
    let title: String
    let author: String
    let url: URL?
}

enum ImageCredits {
    static let all: [ImageCredit] = [
        ImageCredit(id: "sneakers_white", title: "A girl wearing white shoes and skirt; April 2016 (02).jpg", author: "Beryl_snw", url: URL(string: "https://commons.wikimedia.org/wiki/File:A_girl_wearing_white_shoes_and_skirt;_April_2016_(02).jpg")),
        ImageCredit(id: "shoes_running", title: "Eliofeet Black-Green Kalenji.jpg", author: "Benoît Prieur", url: URL(string: "https://commons.wikimedia.org/wiki/File:Eliofeet_Black-Green_Kalenji.jpg")),
        ImageCredit(id: "boots_chukka", title: "Brown leather boots on a wood floor (Unsplash).jpg", author: "Radek Skrzypczak radziu", url: URL(string: "https://commons.wikimedia.org/wiki/File:Brown_leather_boots_on_a_wood_floor_(Unsplash).jpg")),
        ImageCredit(id: "boots_hiking", title: "Boots of a man.jpg", author: "W.carter", url: URL(string: "https://commons.wikimedia.org/wiki/File:Boots_of_a_man.jpg")),
        ImageCredit(id: "headphones_studio", title: "Headphones on wood in black and white (Unsplash).jpg", author: "Corey Blaz blazphoto", url: URL(string: "https://commons.wikimedia.org/wiki/File:Headphones_on_wood_in_black_and_white_(Unsplash).jpg")),
        ImageCredit(id: "headphones_wireless", title: "Headphone-dynamic-color.png", author: "Vijay Verma", url: URL(string: "https://commons.wikimedia.org/wiki/File:Headphone-dynamic-color.png")),
        ImageCredit(id: "headphones_aurum", title: "Headphone-dynamic-premium.png", author: "Vijay Verma", url: URL(string: "https://commons.wikimedia.org/wiki/File:Headphone-dynamic-premium.png")),
        ImageCredit(id: "speaker_portable", title: "Genetic Chinese Speaker.jpg", author: "Pinguinguy", url: URL(string: "https://commons.wikimedia.org/wiki/File:Genetic_Chinese_Speaker.jpg")),
        ImageCredit(id: "turntable_retro", title: "Portable HMV LP - gramophone- phonograph- record player encased in wooden box.jpg", author: "Amitbalani", url: URL(string: "https://commons.wikimedia.org/wiki/File:Portable_HMV_LP_-_gramophone-_phonograph-_record_player_encased_in_wooden_box.jpg")),
        ImageCredit(id: "watch_chrono", title: "Fashion-wristwatch-time-watch (24217032812).jpg", author: "www.Pixel.la Free Stock Photos", url: URL(string: "https://commons.wikimedia.org/wiki/File:Fashion-wristwatch-time-watch_(24217032812).jpg")),
        ImageCredit(id: "watch_vintage", title: "Wristwatch, Hour Angle, Lindbergh, King Collection - DPLA - 48cd2a784bc2d3d4768d0a357ac04d32.jpg", author: "Longines-Wittnauer Watch Co", url: URL(string: "https://commons.wikimedia.org/wiki/File:Wristwatch,_Hour_Angle,_Lindbergh,_King_Collection_-_DPLA_-_48cd2a784bc2d3d4768d0a357ac04d32.jpg")),
        ImageCredit(id: "sunglasses_round", title: "Sunglases.jpg", author: "J.Doniyorovich", url: URL(string: "https://commons.wikimedia.org/wiki/File:Sunglases.jpg")),
        ImageCredit(id: "backpack_canvas", title: "Military backpack 01.jpg", author: "Pegasovagante", url: URL(string: "https://commons.wikimedia.org/wiki/File:Military_backpack_01.jpg")),
        ImageCredit(id: "wallet_leather", title: "Kožená peňaženka.jpg", author: "Zaijo", url: URL(string: "https://commons.wikimedia.org/wiki/File:Ko%C5%BEen%C3%A1_pe%C5%88a%C5%BEenka.jpg")),
        ImageCredit(id: "jacket_denim", title: "Jean jacket.jpg", author: "NikosLikomitros", url: URL(string: "https://commons.wikimedia.org/wiki/File:Jean_jacket.jpg")),
        ImageCredit(id: "tshirt_essential", title: "T-shirt mocup gray.jpg", author: "EdaBojci", url: URL(string: "https://commons.wikimedia.org/wiki/File:T-shirt_mocup_gray.jpg")),
        ImageCredit(id: "sweater_knit", title: "Sweater (Unsplash).jpg", author: "Victoria Bilsborough vicbils", url: URL(string: "https://commons.wikimedia.org/wiki/File:Sweater_(Unsplash).jpg")),
        ImageCredit(id: "mug_ceramic", title: "Coffee mug and biscuit (Unsplash).jpg", author: "Daria Nepriakhina epicantus", url: URL(string: "https://commons.wikimedia.org/wiki/File:Coffee_mug_and_biscuit_(Unsplash).jpg")),
        ImageCredit(id: "serveware_set", title: "Coffee-mug-tea-sugar (23697944933).jpg", author: "www.Pixel.la Free Stock Photos", url: URL(string: "https://commons.wikimedia.org/wiki/File:Coffee-mug-tea-sugar_(23697944933).jpg")),
        ImageCredit(id: "lamp_desk", title: "Laptop and lamp on table (Unsplash).jpg", author: "Tatiana Lapina veila", url: URL(string: "https://commons.wikimedia.org/wiki/File:Laptop_and_lamp_on_table_(Unsplash).jpg")),
        ImageCredit(id: "planter_ceramic", title: "Potted (31758699400).jpg", author: "Alan Levine from Strawberry, United States", url: URL(string: "https://commons.wikimedia.org/wiki/File:Potted_(31758699400).jpg")),
        ImageCredit(id: "candle_pillar", title: "Candle-Vela.jpg", author: "ViajeroExtraviado", url: URL(string: "https://commons.wikimedia.org/wiki/File:Candle-Vela.jpg")),
        ImageCredit(id: "camera_mirrorless", title: "Adapted Lens on Mirrorless Camera (side view).jpg", author: "Hallo3800", url: URL(string: "https://commons.wikimedia.org/wiki/File:Adapted_Lens_on_Mirrorless_Camera_(side_view).jpg")),
        ImageCredit(id: "keyboard_backlit", title: "Keyboard (Unsplash).jpg", author: "Anas Alshanti otenteko", url: URL(string: "https://commons.wikimedia.org/wiki/File:Keyboard_(Unsplash).jpg")),
        ImageCredit(id: "mouse_wired", title: "Computer Mouse 123.jpg", author: "Sathyaprasad Pai", url: URL(string: "https://commons.wikimedia.org/wiki/File:Computer_Mouse_123.jpg")),
        ImageCredit(id: "smartwatch_round", title: "Mobvoi Ticwatch Pro 5, Sandstone.png", author: "SeriouslyBored", url: URL(string: "https://commons.wikimedia.org/wiki/File:Mobvoi_Ticwatch_Pro_5,_Sandstone.png")),
        ImageCredit(id: "band_fitness", title: "Huawei Smartwatch (Band 4).jpg", author: "TheArchivistMan", url: URL(string: "https://commons.wikimedia.org/wiki/File:Huawei_Smartwatch_(Band_4).jpg")),
    ]
}
