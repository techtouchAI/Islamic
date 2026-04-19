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
    const sidebar = document.getElementById('sidebar');
    const sidebarOverlay = document.getElementById('sidebarOverlay');
    const homeSection = document.getElementById('home-section');

    // Load Data
    const savedData = localStorage.getItem('islamic_app_data');
    if (savedData) data = JSON.parse(savedData);
    const theme = localStorage.getItem('theme') || 'light';
    document.body.className = `theme-${theme}`;

    // Apply saved colors
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

    function navigateTo(section, pushState = true) {
        const mainContent = document.getElementById('mainContent');
        mainContent.classList.add('fade-out');

        setTimeout(() => {
        if (pushState && currentSection !== section) {
            history.push(section);
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

        // Visibility
        homeSection.style.display = (section === 'home') ? 'block' : 'none';
        grid.style.display = (section !== 'home') ? 'grid' : 'none';
        searchWrapper.style.display = (['duas', 'visits', 'notes'].includes(section)) ? 'block' : 'none';
        addBtn.style.display = (['duas', 'visits', 'notes'].includes(section)) ? 'flex' : 'none';

        if (section === 'home') {
            initHome();
        } else if (section === 'settings') {
            renderSettings();
        } else {
            renderList(section);
        }

        // Scroll to top
        mainContent.scrollTop = 0;
        mainContent.classList.remove('fade-out');
        }, 150);
    }

    // Handle Hardware Back Button (PWA/Android)
    window.addEventListener('popstate', (event) => {
        if (readerView.classList.contains('active')) {
            readerView.classList.remove('active');
        } else if (contentModal.classList.contains('active')) {
            closeModal();
        } else if (sidebar.classList.contains('active')) {
            closeSidebar();
        } else if (history.length > 1) {
            history.pop();
            navigateTo(history[history.length - 1], false);
        }
    });

    // Home Logic
    function initHome() {
        updateClock();
        setInterval(updateClock, 1000);

        const today = new Date();
        document.getElementById('gregorianDate').textContent = today.toLocaleDateString('ar-SA', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });

        // Basic Hijri approximation or use Intl if supported
        document.getElementById('hijriDate').textContent = today.toLocaleDateString('ar-SA-u-ca-islamic-umalqura', { day: 'numeric', month: 'long', year: 'numeric' });

        // Random content
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
        document.getElementById('digitalClock').textContent = now.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
    }

    // List Logic
    function renderList(section) {
        grid.innerHTML = '';
        const items = data[section] || [];

        if (items.length === 0) {
            grid.innerHTML = `<div class="empty-state" style="text-align:center; padding: 40px; color: #888;">لا يوجد محتوى متاح</div>`;
            return;
        }

        items.forEach(item => {
            const card = document.createElement('div');
            card.className = 'card';
            card.innerHTML = `
                <div class="card-header">
                    <h3 class="card-title">${item.title}</h3>
                    <button class="icon-btn delete-btn" data-id="${item.id}"><span class="material-icons-round">delete_sweep</span></button>
                </div>
                <p class="card-excerpt">${item.content}</p>
            `;
            card.onclick = (e) => {
                if (e.target.closest('.delete-btn')) {
                    e.stopPropagation();
                    if (confirm('هل أنت متأكد من الحذف؟')) {
                        deleteItem(section, item.id);
                    }
                } else {
                    openReader(item);
                }
            };
            grid.appendChild(card);
        });
    }

    // Reader & Sharing
    function openReader(item) {
        document.getElementById('readerTitle').textContent = item.title;
        document.getElementById('readerText').textContent = item.content;
        readerView.classList.add('active');
        window.history.pushState({view: 'reader'}, '');
        updateFontSize();
    }

    document.getElementById('closeReader').addEventListener('click', () => {
        readerView.classList.remove('active');
        window.history.back();
    });

    document.getElementById('shareBtn').addEventListener('click', async () => {
        const title = document.getElementById('readerTitle').textContent;
        const text = document.getElementById('readerText').textContent;
        if (navigator.share) {
            await navigator.share({ title, text: `${title}\n\n${text}` });
        } else {
            alert('المشاركة غير مدعومة');
        }
    });

    // Settings
    function renderSettings() {
        const currentPrimary = getComputedStyle(document.documentElement).getPropertyValue('--primary').trim();
        const currentBg = localStorage.getItem('app-bg-color') || '#fdfbf7';

        grid.innerHTML = `
            <div class="card">
                <div class="card-header"><h3 class="card-title">المظهر والتخصيص</h3></div>
                <div class="setting-row">
                    <span>الوضع الليلي</span>
                    <button id="themeToggleBtn" class="icon-btn ${document.body.classList.contains('theme-dark') ? 'primary-bg' : ''}">
                        <span class="material-icons-round">${document.body.classList.contains('theme-dark') ? 'dark_mode' : 'light_mode'}</span>
                    </button>
                </div>
                <div class="setting-row">
                    <span>لون التطبيق</span>
                    <div class="color-palette">
                        <div class="color-circle" data-color="#d4af37" style="background:#d4af37"></div>
                        <div class="color-circle" data-color="#2c3e50" style="background:#2c3e50"></div>
                        <div class="color-circle" data-color="#27ae60" style="background:#27ae60"></div>
                        <div class="color-circle" data-color="#e74c3c" style="background:#e74c3c"></div>
                    </div>
                </div>
                <div class="setting-row">
                    <span>لون الخلفية</span>
                    <input type="color" id="bgColorPicker" value="${currentBg}">
                </div>
                <div class="setting-row">
                    <span>صورة الخلفية</span>
                    <button id="bgImageBtn" class="btn btn-primary" style="font-size:0.8rem; padding:8px;">اختر صورة</button>
                    <button id="removeBgImageBtn" class="btn btn-primary" style="font-size:0.8rem; padding:8px; background:#e74c3c;">حذف</button>
                </div>
            </div>
            <div class="card">
                <div class="card-header"><h3 class="card-title">إدارة البيانات</h3></div>
                <div class="btn-group">
                    <button id="exportBtn" class="btn btn-primary">تصدير نسخة احتياطية</button>
                    <button id="importBtn" class="btn btn-primary" style="background:#2c3e50;">استيراد نسخة احتياطية</button>
                    <button id="clearBtn" class="btn btn-primary" style="background:#c0392b;">مسح جميع البيانات</button>
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
                renderSettings();
            };
        });

        document.getElementById('bgColorPicker').oninput = (e) => {
            const color = e.target.value;
            document.body.style.backgroundImage = 'none';
            document.body.style.backgroundColor = color;
            localStorage.setItem('app-bg-color', color);
            localStorage.removeItem('app-bg-image');
        };

        document.getElementById('bgImageBtn').onclick = () => {
            const input = document.createElement('input');
            input.type = 'file';
            input.accept = 'image/*';
            input.onchange = (e) => {
                const file = e.target.files[0];
                const reader = new FileReader();
                reader.onload = (event) => {
                    const dataUrl = event.target.result;
                    document.body.style.backgroundImage = `url(${dataUrl})`;
                    document.body.style.backgroundSize = 'cover';
                    document.body.style.backgroundAttachment = 'fixed';
                    localStorage.setItem('app-bg-image', dataUrl);
                };
                reader.readAsDataURL(file);
            };
            input.click();
        };

        document.getElementById('removeBgImageBtn').onclick = () => {
            document.body.style.backgroundImage = 'none';
            localStorage.removeItem('app-bg-image');
            const savedBg = localStorage.getItem('app-bg-color') || '#fdfbf7';
            document.body.style.backgroundColor = savedBg;
        };

        document.getElementById('exportBtn').onclick = exportData;
        document.getElementById('importBtn').onclick = () => {
            const input = document.createElement('input');
            input.type = 'file';
            input.accept = '.json';
            input.onchange = importData;
            input.click();
        };
        document.getElementById('clearBtn').onclick = () => {
            if(confirm('هل أنت متأكد من حذف جميع البيانات؟ لا يمكن التراجع عن هذا الإجراء.')) {
                localStorage.removeItem('islamic_app_data');
                location.reload();
            }
        };
    }

    // Data Actions
    function deleteItem(section, id) {
        data[section] = data[section].filter(i => i.id !== id);
        saveData();
        renderList(section);
        updateBadges();
    }

    function saveData() {
        localStorage.setItem('islamic_app_data', JSON.stringify(data));
    }

    function updateBadges() {
        document.getElementById('duasBadge').textContent = data.duas.length;
        document.getElementById('visitsBadge').textContent = data.visits.length;
        document.getElementById('notesBadge').textContent = data.notes.length;
    }

    function exportData() {
        const blob = new Blob([JSON.stringify(data)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'aldhakereen_backup.json';
        a.click();
    }

    function importData(e) {
        const file = e.target.files[0];
        const reader = new FileReader();
        reader.onload = (event) => {
            try {
                data = JSON.parse(event.target.result);
                saveData();
                alert('تم استيراد البيانات بنجاح');
                location.reload();
            } catch (err) {
                alert('خطأ في استيراد البيانات');
            }
        };
        reader.readAsText(file);
    }

    // Font Logic
    function updateFontSize() {
        document.getElementById('readerText').style.fontSize = (fontSize / 100 * 1.6) + 'rem';
        document.getElementById('fontSizeLabel').textContent = fontSize + '%';
    }

    document.getElementById('increaseFont').onclick = () => { fontSize += 10; updateFontSize(); };
    document.getElementById('decreaseFont').onclick = () => { if (fontSize > 50) fontSize -= 10; updateFontSize(); };

    // Add Modal Logic
    addBtn.onclick = () => {
        contentModal.classList.add('active');
        modalOverlay.classList.add('active');
        window.history.pushState({view: 'modal'}, '');
    };

    function closeModal() {
        contentModal.classList.remove('active');
        modalOverlay.classList.remove('active');
    }

    document.querySelector('.close-modal').onclick = () => { window.history.back(); };

    document.getElementById('saveItemBtn').onclick = () => {
        const title = document.getElementById('itemTitle').value;
        const content = document.getElementById('itemContent').value;
        if (title && content) {
            data[currentSection].unshift({ id: Date.now(), title, content });
            saveData();
            renderList(currentSection);
            updateBadges();
            window.history.back();
        }
    };

    // Initial history state
    window.history.replaceState({view: 'home'}, '');
});
