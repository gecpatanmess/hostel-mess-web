'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "0bfa5a569e29d888cf842d99a2db40da",
".git/config": "ebac0ce827bdaf112eb090660a9bda20",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "44ad595963ed99b6a15b8de6b4525329",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "0516120238ff7cd1bc359aac999b61be",
".git/logs/refs/heads/main": "418d8d56c0f3ad717a2d973894d5471d",
".git/logs/refs/remotes/origin/main": "932f75cef2e4a154d2eef1d451a87dd3",
".git/objects/01/1842b856d2844c35f671e492a3793c1dea487f": "9a7fa59443b8925d7b787ea6939b9d2f",
".git/objects/05/a9c09613574de9b77071261d4429ad6457f4f3": "ac4627b63d6bbc4a63e59c613b45193e",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/0e/c78219cc27fed65ad0f8a0b3acdaaf72149620": "58ef02fedf267cafdc1c51a0a859c581",
".git/objects/12/12a83167e2f12c70d87de57ec10bdb8467edea": "8eabc958cb5f7d8f54c8f58a1d3fcb75",
".git/objects/12/6b5d2c6fb347d66ea3c759a640e46de3f2c1a6": "f90d833b757239a1076ee037fa16bd4d",
".git/objects/15/dab85f606bb4ec3d997eca769ee5dbf9a9f8b4": "8bec7cf41f94831b9dc3d5028521ce46",
".git/objects/16/4315734aa47211f6d402e30aa15a5d106d8830": "df088ed25d9700d210c0146a0943fe4d",
".git/objects/19/adfe5b7311e21c876c84057f2251e19e6b20c0": "257fb476f90c558f89fd5b59a785aaf9",
".git/objects/1d/b76e1d05c2611f11c6a9c53ddfe71421c7f71d": "baab75260c4ccff80bee2e8ca24146d4",
".git/objects/1e/54a86f80eec9b3da9d72d436cef5639fa8dc66": "3ec681bd76761614c211bd24c8cc4cee",
".git/objects/28/6a48c5a453d73fb5ce555f9a0656a923e22e96": "99f80d4c240a77ee916c880b7fc4f03d",
".git/objects/28/8ab23aa74b7433f868a9c31fdae018a80b7056": "76b34f09aea7e1cff6d44753b88dd12a",
".git/objects/2c/e92473c0af3d945b48f5b36ca42cee51999f1f": "4138321eef47bda12893af0b1cde98dc",
".git/objects/30/6942dc5bda024438722d4da845f397d2b10e14": "682a06660c7a1bece06811374e7444ab",
".git/objects/35/1ff3e106eb334dde80aac314d6e6de0a47bc61": "ee8dd8d1bf78a998cb91e5d3a801f051",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3b/98c176bbb04cbf104fddb61f0767dada719822": "3b2eb3efcd1fa625f64630b7da878caf",
".git/objects/3e/24b5e242bceb8b01e41eb5bf8f00e99f56a1b2": "ddb84cbd8df9bd87580c4a8f15df1ecb",
".git/objects/3f/7d633f4adeb4ca5b68b0e6b094257a68f78c82": "bc75a11d3c30d64544bf88abd7ccf991",
".git/objects/3f/f0ff442fecc503b98d8b006992a44884a2fcc0": "a68ca8997e18b8d06be0d5ade05fa9c7",
".git/objects/47/84e8dd3f3826c5e9dd382c6bd343f77f142d19": "7149f6224996c3237ed7fc06ae29df71",
".git/objects/49/f7d4b3c7f11575c18da76baf6126af5dc50fd4": "b1f4803b23aff24fe4dfc22efcea9738",
".git/objects/4e/0d9f8efb86f69fce020088c7bb426809057e80": "f37c92205b1ebd3f3903b5632beaf235",
".git/objects/4f/38f7b0db5ca279f1eea60c97cdff1afd99e3c0": "b7353a014f262e923c8096900d5917ba",
".git/objects/4f/4474881805f2f4daeaad1a56864ac4da41085f": "4f00622349a057f16f93a85a5d7c4434",
".git/objects/50/d77b6421c1c1caf21e68dca74e8ba518c56480": "65345d765e71d37935c071773c9db50c",
".git/objects/50/ead27f7e11bb6b1d41669e62a8d008f352eb2f": "af6d0a27dff2520d21f885968e7075e9",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/53/e225ee8f69609dab29dc01fdcc9547dc2fa2e4": "27318afb8b3fa87dff16489932ee69a4",
".git/objects/57/1b64b3824d91b030914f7cc7a1358e1f3886b5": "0f904890c2de6d53de50b930a9b766eb",
".git/objects/5c/eb01e7544c23bf596fc9e575cef4d2e123f2e1": "868f2b747866228d10d1c4ce05a015ed",
".git/objects/5e/4eded68beba396abca9a65c9f89b135e565bf7": "8057e285ebf57548114f206f80d0d041",
".git/objects/5e/769fc4718602bc34ba99a5cadcd90e01afa6df": "4ab178d5c7b489d62bdbaff845af52d8",
".git/objects/5e/8448cfdd8ff56e1090bdec7886e124dc40e632": "bb77138b3a7314f7a73f388f2a84d9ad",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6c/8d6618c0a2882f0b994a9ea6f0617a3d102de7": "c6498917958fae1b1c7cb28dda6b5688",
".git/objects/6d/f2b253603094de7f39886aae03181c686e375b": "4e432986780adf1da707b08f0bc71809",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/73/5fe05d2d9072b1c725a7c5304bd56445371b1e": "60897b768b1848dede52743f3835bccd",
".git/objects/75/7b0999e57af77d2a7bc7dcc0ed6d737ff49e33": "868d33c64401702f54c3e602e7c24ff5",
".git/objects/77/0aa7d82e361fba35bb284a0d0c5577b00a9cec": "9060bda9d7ba0d45f97f2722598375ff",
".git/objects/79/49f1eb8314debe6b12a9ebf72218c40b3457bf": "2a06b2f6a25364f637597d8df89727b5",
".git/objects/7a/422e784caff1584a14177fee62111e377be025": "95b03639c69ffadf79636b518751b4cd",
".git/objects/7b/e3feb87c4139633fed0ea5f50178236ef21609": "5a22617a158b7d4da60dcd61e7884551",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/7d/63516284bfdbcaa17636b2247011e1c6ed8e74": "73884cada1a6a7db03aff18bc2a8d7ed",
".git/objects/82/147f828079701dedd9b8b5c47fa9723967c541": "58ce7856cb3fa1a9408d3899f1175a7e",
".git/objects/82/52289682a65579f07efd66800b3f9a80d2edfe": "78f567ed22bd208266a3e228e26d3dfc",
".git/objects/85/50198d3b2af85ab2761a1e27122f7e4bc0fa92": "8918cb862b4f94935623ca877252356a",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/85/7ff34134f1c72e8ce5d0a88c2070f1e629a5de": "4529e92828ada8019ce1741d08042680",
".git/objects/86/34a97c911ebed728ca5d3ca1ecbd526e7e6533": "a19c71a985a50a082c95d30c9c7ade17",
".git/objects/86/6a00bfe5220a8b7f6b1b76869c19aae282ba89": "482481da22a517eaec8a8f4584ab674d",
".git/objects/86/c4dd389e7158213c0c03f14c5ec2f2656085b4": "ce22968a4e5a2f18d30a031f741c5604",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/8e/bd0524f9dbe0b9797006d4e25803c5f217fd25": "0027f0948f62ef511c0fa8c418b5447d",
".git/objects/92/f25db52b8549a3e6c24f3a0b44927cf0707b0b": "e416c19c27112ad3b3e1ca9f997c60db",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/99/ad9596c53fc1e84a318beddf4f9f78030ebb99": "2c6d381c1ac9fc535d3b8109b36e0399",
".git/objects/9a/ba6b320a5312755f6444314b02ee7291383659": "7abd48077a8f163a88690808c43eba74",
".git/objects/9b/061b6f029e327788bc49245c43a67f2a7b3f98": "25801f1f90d8f612864a2fb1e94e050c",
".git/objects/9b/6e12b486085c7731e8a3bff70f847c0ac82679": "440c026f89034ea72f27a838bbe4c0f0",
".git/objects/a3/fe1207c8b46caaa2f101614834ecf2565b173e": "c7ec6c27ee3e93171910f11029d42fbe",
".git/objects/a3/fe206086d8e2e4fe6bd8a1280d280507b54608": "d61b8c6cd52819102d2b288c01178b43",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/b3/39ae3187eadacfd3960f047283f7b31ce28aff": "8c9f8af759ef15a672fb4d8728ecb331",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/bd/67267d4e9e3d7c3d323528fc1f2fe8919b0f55": "730ea56cc4e229a2fb9d39bf70e316d1",
".git/objects/bd/b00e6faa9a0e6e5c36cbae405dae4a5bd73e51": "5fbdc7629e53bc2bc89261437bf2f572",
".git/objects/be/fce6af890a4edf6d3c858878b30c1c2e2cd803": "a6c70daafc28408c562234b3d09e0578",
".git/objects/bf/deb84592d990baef5ad318c241115237ac0229": "cb680d23bc84d8c28ced97c2261b457b",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/c9/fb146c66a474813c214cd6a1f1d3e958893775": "8aa5ae60af1604f3ea5bc48669dafc58",
".git/objects/cd/34ab07bdde9db5816815a70d5eea043e850bd0": "765220d7290b611cfa63c039ee1e7d26",
".git/objects/cf/25d2eac5cb1c900d561d81c7c8c4a56edb468d": "7dd487d9a57593fe9707668cda36e800",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/df/85f092bc5374d2bc9376efdfaf21c8c0316c82": "1232dd7865eb0a2b995125c67faf7ab6",
".git/objects/e4/57c749629ae8ed409a93e855ca2cae9c0db6f2": "8015f1e4a23527d564ef83e9f7481a29",
".git/objects/e6/2450a1f2c465ee824ddda3c2c92188128c9cce": "7c11de59fc6b99c62b1c1af596fff0ee",
".git/objects/e6/d8fcd602c27187cab6f2f17e90e5928fec03b6": "01aa34dc53cedbded40dc172241dead7",
".git/objects/e7/9c142ef52f70d0727953d06b0cab2cc1d621bb": "d3c29cbe398063cdda610e7200376f52",
".git/objects/e9/2535f36942a1d2f58e97e4ee7a33aab302dc09": "42a318db2c949667c31a04c614c0272b",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/eb/2c8735c3a55f863dbfddeea3dbf0a3db35d450": "5972ee9d9e2e702d43e621bd31bbecd0",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ec/2449c90f6959775970a8672ad04f38621db4fe": "e19a7ad861d25a3dbe1ac37ddb3aac36",
".git/objects/ed/033340efa64a7e3e05fdfc386dce34aaaa6e4b": "a28903fa0d7546074f5c4f28dbb9f7f9",
".git/objects/ef/725a3597ff8fc0b7958ab5d16ada9e28553aec": "49765b51187c1a59afc75a20ef11f7d2",
".git/objects/f2/c9ebab0d53e1f95e6b4943880321d0dc187ade": "88908e835f3a41103cb8bf0c6848b093",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/f8/4e256989d475f2bfb0e60c33d9b809ff44a80b": "0cf7f5e98acff5cf420acac8ae2fb024",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/objects/fe/239ae4e7f3dae01d0c435653502df1e6785e7e": "6bf8df27d4cdab714f143461a1c64062",
".git/objects/fe/ef09b635e13007ef4f68f76f8608bcea16c859": "262aa35037792cc3bec7860142f1acf1",
".git/refs/heads/main": "049e60c8d15e53f053c10abc8c0871eb",
".git/refs/remotes/origin/main": "049e60c8d15e53f053c10abc8c0871eb",
"assets/AssetManifest.bin": "e4ada9e17cea43068385299753d2a7b4",
"assets/AssetManifest.bin.json": "c792ccd8b424335418ebab0cae015bbf",
"assets/FontManifest.json": "2b52acee7bee9f34d372a965ef37754f",
"assets/fonts/MaterialIcons-Regular.otf": "b7faec3c656ece9ee04800e10ab3b150",
"assets/NOTICES": "338ff0e806758c9cc1cf774db2818742",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/syncfusion_flutter_pdfviewer/assets/fonts/RobotoMono-Regular.ttf": "5b04fdfec4c8c36e8ca574e40b7148bb",
"assets/packages/syncfusion_flutter_pdfviewer/assets/icons/dark/highlight.png": "2aecc31aaa39ad43c978f209962a985c",
"assets/packages/syncfusion_flutter_pdfviewer/assets/icons/dark/squiggly.png": "68960bf4e16479abb83841e54e1ae6f4",
"assets/packages/syncfusion_flutter_pdfviewer/assets/icons/dark/strikethrough.png": "72e2d23b4cdd8a9e5e9cadadf0f05a3f",
"assets/packages/syncfusion_flutter_pdfviewer/assets/icons/dark/underline.png": "59886133294dd6587b0beeac054b2ca3",
"assets/packages/syncfusion_flutter_pdfviewer/assets/icons/light/highlight.png": "2fbda47037f7c99871891ca5e57e030b",
"assets/packages/syncfusion_flutter_pdfviewer/assets/icons/light/squiggly.png": "9894ce549037670d25d2c786036b810b",
"assets/packages/syncfusion_flutter_pdfviewer/assets/icons/light/strikethrough.png": "26f6729eee851adb4b598e3470e73983",
"assets/packages/syncfusion_flutter_pdfviewer/assets/icons/light/underline.png": "a98ff6a28215341f764f96d627a5d0f5",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "77c8bd5739973630f4a6ba102e278575",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "17b6eab3312cc625a1067fbb3bc0aa4e",
"/": "17b6eab3312cc625a1067fbb3bc0aa4e",
"main.dart.js": "a878aded888a3c64cf88e94eaa20dde2",
"manifest.json": "1eebf019c0a928268f44d1f28665e8f3",
"version.json": "2bd25a22b457202b76ed4a0bc021c71a"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
