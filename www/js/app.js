document.addEventListener('DOMContentLoaded', () => {
    // State Management
    let currentSection = 'home';
    let fontSize = 100;
    let history = ['home'];

    let data = {
        duas: [
            { id: 1, title: 'دعاء الصباح', content: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.' },
            { id: 2, title: 'دعاء المساء', content: 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.' }
        ],
        visits: [
            { id: 1, title: 'زيارة عاشوراء', content: 'السَّلامُ عَلَيْكَ يا أَبا عَبْدِ اللهِ، السَّلامُ عَلَيْكَ يَا بْنَ رَسُولِ اللهِ، السَّلامُ عَلَيْكَ يا خِيَرَةَ اللهِ وَابْنَ خِيَرَتِهِ، السَّلامُ عَلَيْكَ يَا بْنَ أَمِيرِ الْمُؤْمِنِينَ وَابْنَ سَيِّدِ الْوَصِيِّينَ.' }
        ],
        notes: []
    };

    // Elements
    const grid = document.getElementById('contentGrid');
    const sectionTitle = document.getElementById('sectionTitle');
    const loadingScreen = document.getElementById('loadingScreen');
    const readerView = document.getElementById('readerView');
    const contentModal = document.getElementById('contentModal');
    const modalOverlay = document.getElementById('modalOverlay');
    const searchWrapper = document.getElementById('searchWrapper');
    const searchInput = document.getElementById('searchInput');
    const addBtn = document.getElementById('addBtn');
    const backBtn = document.getElementById('backBtn');
    const sidebar = document.getElementById('sidebar');
    const sidebarOverlay = document.getElementById('sidebarOverlay');
    const homeSection = document.getElementById('home-section');

    // Load Data & Settings
    const savedData = localStorage.getItem('islamic_app_data');
    if (savedData) data = JSON.parse(savedData);

    const theme = localStorage.getItem('theme') || 'light';
    document.body.className = `theme-${theme}`;

    const savedPrimary = localStorage.getItem('app-primary-color');
    if (savedPrimary) document.documentElement.style.setProperty('--primary', savedPrimary);

    const savedBg = localStorage.getItem('app-bg-color');
    if (savedBg) document.body.style.backgroundColor = savedBg;

    const savedBgImg = localStorage.getItem('app-bg-image');
    if (savedBgImg) {
        document.body.style.backgroundImage = `url(${savedBgImg})`;
        document.body.style.backgroundSize = 'cover';
        document.body.style.backgroundAttachment = 'fixed';
    }

    const savedOpacity = localStorage.getItem('app-card-opacity') || '1';
    document.documentElement.style.setProperty('--card-opacity', savedOpacity);

    // Initialize
    setTimeout(() => {
        loadingScreen.style.opacity = '0';
        setTimeout(() => loadingScreen.style.display = 'none', 500);
        updateBadges();
        initHome();
    }, 1500);

    // Sidebar Toggle
    document.getElementById('menuBtn').addEventListener('click', () => {
        sidebar.classList.add('active');
        sidebarOverlay.classList.add('active');
    });

    sidebarOverlay.addEventListener('click', closeSidebar);
    function closeSidebar() {
        sidebar.classList.remove('active');
        sidebarOverlay.classList.remove('active');
    }

    // Navigation
    document.querySelectorAll('.menu-item').forEach(btn => {
        btn.addEventListener('click', () => {
            const section = btn.dataset.section;
            navigateTo(section);
            closeSidebar();
        });
    });

    backBtn.addEventListener('click', () => {
        if (history.length > 1) {
            window.history.back();
        }
    });

    function navigateTo(section, pushState = true) {
        const mainContent = document.getElementById('mainContent');
        mainContent.classList.add('fade-out');

        setTimeout(() => {
            if (pushState && currentSection !== section) {
                history.push(section);
                window.history.pushState({ section }, '');
            }

            currentSection = section;
            document.querySelectorAll('.menu-item').forEach(item => {
                item.classList.toggle('active', item.dataset.section === section);
            });

            const titles = {
                'home': 'الرئيسية',
                'duas': 'الأدعية',
                'visits': 'الزيارات',
                'notes': 'الملاحظات',
                'settings': 'الإعدادات'
            };
            sectionTitle.textContent = titles[section];

            // UI State
            homeSection.style.display = (section === 'home') ? 'block' : 'none';
            grid.style.display = (section !== 'home') ? 'grid' : 'none';
            searchWrapper.style.display = (['duas', 'visits', 'notes'].includes(section)) ? 'block' : 'none';
            addBtn.style.display = (['duas', 'visits', 'notes'].includes(section)) ? 'flex' : 'none';
            backBtn.style.display = (section !== 'home') ? 'flex' : 'none';

            if (section === 'home') initHome();
            else if (section === 'settings') renderSettings();
            else renderList(section);

            mainContent.scrollTop = 0;
            mainContent.classList.remove('fade-out');
        }, 200);
    }

    window.addEventListener('popstate', (event) => {
        if (readerView.classList.contains('active')) {
            readerView.classList.remove('active');
        } else if (contentModal.classList.contains('active')) {
            closeModal();
        } else if (sidebar.classList.contains('active')) {
            closeSidebar();
        } else if (history.length > 1) {
            history.pop();
            const prevSection = history[history.length - 1];
            navigateTo(prevSection, false);
        }
    });

    // Home Section (12h format & scroll fix)
    function initHome() {
        updateClock();
        if (window.clockInterval) clearInterval(window.clockInterval);
        window.clockInterval = setInterval(updateClock, 1000);

        const today = new Date();
        document.getElementById('gregorianDate').textContent = today.toLocaleDateString('ar-SA', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });

        // Dynamic Hijri Date
        try {
            const hijriFormatter = new Intl.DateTimeFormat('ar-SA-u-ca-islamic-umalqura', { day: 'numeric', month: 'long', year: 'numeric' });
            document.getElementById('hijriDate').textContent = hijriFormatter.format(today);
        } catch (e) {
            console.error('Hijri format error', e);
        }

        // Random Content
        const randomDua = data.duas[Math.floor(Math.random() * data.duas.length)];
        const randomVisit = data.visits[Math.floor(Math.random() * data.visits.length)];

        if (randomDua) {
            document.getElementById('dailyDuaTitle').textContent = randomDua.title;
            document.getElementById('dailyDuaText').textContent = randomDua.content;
            document.getElementById('dailyDua').onclick = () => openReader(randomDua);
        }
        if (randomVisit) {
            document.getElementById('dailyVisitTitle').textContent = randomVisit.title;
            document.getElementById('dailyVisitText').textContent = randomVisit.content;
            document.getElementById('dailyVisit').onclick = () => openReader(randomVisit);
        }
    }

    function updateClock() {
        const now = new Date();
        const clockEl = document.getElementById('digitalClock');
        if (clockEl) {
            let timeStr = now.toLocaleTimeString('en-US', { hour12: true, hour: '2-digit', minute: '2-digit', second: '2-digit' });
            timeStr = timeStr.replace('AM', 'ص').replace('PM', 'م');
            clockEl.textContent = timeStr;
        }
    }

    // List & Reader
    function renderList(section) {
        grid.innerHTML = '';
        const items = data[section] || [];
        if (items.length === 0) {
            grid.innerHTML = `<div class="card" style="text-align:center; padding: 40px; color: #888;">لا يوجد محتوى متاح حالياً</div>`;
            return;
        }

        items.forEach(item => {
            const card = document.createElement('div');
            card.className = 'card';
            card.innerHTML = `
                <div class="card-header">
                    <h3 class="card-title">${item.title}</h3>
                    <button class="icon-btn delete-btn"><span class="material-icons-round">delete_outline</span></button>
                </div>
                <p class="card-excerpt">${item.content}</p>
            `;
            card.onclick = (e) => {
                if (e.target.closest('.delete-btn')) {
                    e.stopPropagation();
                    if (confirm('هل أنت متأكد من الحذف؟')) {
                        data[section] = data[section].filter(i => i.id !== item.id);
                        saveData();
                        renderList(section);
                        updateBadges();
                    }
                } else {
                    openReader(item);
                }
            };
            grid.appendChild(card);
        });
    }

    function openReader(item) {
        document.getElementById('readerTitle').textContent = item.title;
        document.getElementById('readerText').textContent = item.content;
        readerView.classList.add('active');
        window.history.pushState({ view: 'reader' }, '');
        updateFontSize();
    }

    document.getElementById('closeReader').onclick = () => window.history.back();

    // Font Controls (- Aa +)
    document.getElementById('increaseFont').onclick = () => { fontSize += 10; updateFontSize(); };
    document.getElementById('decreaseFont').onclick = () => { if (fontSize > 50) fontSize -= 10; updateFontSize(); };
    function updateFontSize() {
        document.getElementById('readerText').style.fontSize = (fontSize / 100 * 1.5) + 'rem';
        document.getElementById('fontSizeLabel').textContent = fontSize + '%';
    }

    // Sharing
    document.getElementById('shareBtn').onclick = async () => {
        const title = document.getElementById('readerTitle').textContent;
        const text = document.getElementById('readerText').textContent;
        if (navigator.share) {
            await navigator.share({ title, text: `${title}\n\n${text}` });
        } else {
            alert('المشاركة غير مدعومة');
        }
    };

    document.getElementById('copyBtn').onclick = () => {
        const text = document.getElementById('readerText').textContent;
        navigator.clipboard.writeText(text).then(() => alert('تم النسخ بنجاح'));
    };

    // Settings (Fixed color response & transparency)
    function renderSettings() {
        const currentOpacity = localStorage.getItem('app-card-opacity') || '1';
        grid.innerHTML = `
            <div class="card">
                <div class="card-header"><h3 class="card-title">المظهر والتخصيص</h3></div>
                <div class="setting-row">
                    <span>الوضع الليلي</span>
                    <button id="themeToggleBtn" class="nav-text-btn ${document.body.classList.contains('theme-dark') ? 'primary-bg' : ''}" style="padding: 5px 10px; border-radius: 8px;">
                        <span class="material-icons-round" style="font-size:18px;">${document.body.classList.contains('theme-dark') ? 'dark_mode' : 'light_mode'}</span>
                        <span>${document.body.classList.contains('theme-dark') ? 'مفعل' : 'معطل'}</span>
                    </button>
                </div>
                <div class="setting-row">
                    <span>لون التطبيق الأساسي</span>
                    <div class="color-palette">
                        <div class="color-circle" data-color="#d4af37" style="background:#d4af37"></div>
                        <div class="color-circle" data-color="#2c3e50" style="background:#2c3e50"></div>
                        <div class="color-circle" data-color="#27ae60" style="background:#27ae60"></div>
                        <div class="color-circle" data-color="#e74c3c" style="background:#e74c3c"></div>
                    </div>
                </div>
                <div class="setting-row">
                    <span>شفافية القوائم</span>
                    <input type="range" id="opacitySlider" min="0.5" max="1" step="0.05" value="${currentOpacity}" style="width: 100px;">
                </div>
                <div class="setting-row">
                    <span>صورة الخلفية</span>
                    <div class="btn-group" style="flex-direction:row; gap:5px;">
                        <button id="bgImageBtn" class="btn btn-primary" style="font-size:0.7rem; padding:5px 10px;">اختيار</button>
                        <button id="removeBgImageBtn" class="btn btn-primary" style="font-size:0.7rem; padding:5px 10px; background:#e74c3c;">حذف</button>
                    </div>
                </div>
            </div>
            <div class="card">
                <div class="card-header"><h3 class="card-title">إدارة البيانات</h3></div>
                <div class="btn-group">
                    <button id="exportBtn" class="btn btn-primary">تصدير البيانات</button>
                    <button id="importBtn" class="btn btn-primary" style="background:#2c3e50;">استيراد البيانات</button>
                </div>
            </div>
        `;

        document.getElementById('themeToggleBtn').onclick = () => {
            const isDark = document.body.classList.toggle('theme-dark');
            localStorage.setItem('theme', isDark ? 'dark' : 'light');
            renderSettings();
        };

        document.querySelectorAll('.color-circle').forEach(circle => {
            circle.onclick = () => {
                const color = circle.dataset.color;
                document.documentElement.style.setProperty('--primary', color);
                localStorage.setItem('app-primary-color', color);
                alert('تم تغيير لون التطبيق بنجاح');
            };
        });

        document.getElementById('opacitySlider').oninput = (e) => {
            const val = e.target.value;
            document.documentElement.style.setProperty('--card-opacity', val);
            localStorage.setItem('app-card-opacity', val);
        };

        document.getElementById('bgImageBtn').onclick = () => {
            const input = document.createElement('input');
            input.type = 'file';
            input.accept = 'image/*';
            input.onchange = (e) => {
                const reader = new FileReader();
                reader.onload = (event) => {
                    const dataUrl = event.target.result;
                    document.body.style.backgroundImage = `url(${dataUrl})`;
                    document.body.style.backgroundSize = 'cover';
                    document.body.style.backgroundAttachment = 'fixed';
                    localStorage.setItem('app-bg-image', dataUrl);
                };
                reader.readAsDataURL(e.target.files[0]);
            };
            input.click();
        };

        document.getElementById('removeBgImageBtn').onclick = () => {
            document.body.style.backgroundImage = 'none';
            localStorage.removeItem('app-bg-image');
        };

        document.getElementById('exportBtn').onclick = () => {
            const blob = new Blob([JSON.stringify(data)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a'); a.href = url; a.download = 'aldhakereen_data.json'; a.click();
        };

        document.getElementById('importBtn').onclick = () => {
            const input = document.createElement('input'); input.type = 'file'; input.accept = '.json';
            input.onchange = (e) => {
                const reader = new FileReader();
                reader.onload = (ev) => {
                    data = JSON.parse(ev.target.result); saveData(); updateBadges(); alert('تم الاستيراد بنجاح');
                };
                reader.readAsText(e.target.files[0]);
            };
            input.click();
        };
    }

    // Utilities
    function saveData() { localStorage.setItem('islamic_app_data', JSON.stringify(data)); }
    function updateBadges() {
        document.getElementById('duasBadge').textContent = data.duas.length;
        document.getElementById('visitsBadge').textContent = data.visits.length;
        document.getElementById('notesBadge').textContent = data.notes.length;
    }
    function closeModal() {
        contentModal.classList.remove('active');
        modalOverlay.classList.remove('active');
    }

    // Add Modal
    addBtn.onclick = () => {
        contentModal.classList.add('active');
        modalOverlay.classList.add('active');
        window.history.pushState({ view: 'modal' }, '');
    };
    document.querySelector('.close-modal').onclick = () => window.history.back();
    document.getElementById('saveItemBtn').onclick = () => {
        const title = document.getElementById('itemTitle').value;
        const content = document.getElementById('itemContent').value;
        if (title && content) {
            data[currentSection].unshift({ id: Date.now(), title, content });
            saveData(); renderList(currentSection); updateBadges(); window.history.back();
        }
    };

    // Initial state
    window.history.replaceState({ section: 'home' }, '');
});
