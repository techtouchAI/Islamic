document.addEventListener('DOMContentLoaded', () => {
    // State Management
    let currentSection = 'duas';
    let fontSize = 100;
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

    // Load from LocalStorage
    const savedData = localStorage.getItem('islamic_app_data');
    if (savedData) data = JSON.parse(savedData);

    const theme = localStorage.getItem('theme') || 'light';
    document.body.className = `theme-${theme}`;

    // Elements
    const grid = document.getElementById('contentGrid');
    const sectionTitle = document.getElementById('sectionTitle');
    const loadingScreen = document.getElementById('loadingScreen');
    const readerView = document.getElementById('readerView');
    const contentModal = document.getElementById('contentModal');
    const modalOverlay = document.getElementById('modalOverlay');
    const searchInput = document.getElementById('searchInput');

    // Initialize
    setTimeout(() => {
        loadingScreen.style.opacity = '0';
        setTimeout(() => loadingScreen.style.display = 'none', 500);
        renderSection(currentSection);
    }, 1500);

    // Navigation
    document.querySelectorAll('.nav-item').forEach(btn => {
        btn.addEventListener('click', () => {
            const activeNav = document.querySelector('.nav-item.active');
            if (activeNav) activeNav.classList.remove('active');
            btn.classList.add('active');
            currentSection = btn.dataset.section;

            if (currentSection === 'settings') {
                renderSettings();
            } else {
                renderSection(currentSection);
            }
            sectionTitle.textContent = btn.querySelector('span:last-child').textContent;
            searchInput.value = '';
        });
    });

    function renderSection(section) {
        grid.innerHTML = '';
        const items = data[section] || [];

        if (items.length === 0) {
            grid.innerHTML = `
                <div class="empty-state" style="text-align:center; padding: 60px 20px; color: #888; animation: fadeIn 0.5s ease;">
                    <span class="material-icons-round" style="font-size: 64px; color: var(--primary); opacity: 0.5;">inventory_2</span>
                    <p style="margin-top: 15px; font-weight: 600;">لا يوجد محتوى متاح حالياً</p>
                </div>`;
            return;
        }

        items.forEach((item, index) => {
            const card = document.createElement('div');
            card.className = 'card';
            card.style.animationDelay = (index * 0.05) + 's';
            card.innerHTML = `
                <div class="card-header">
                    <h3 class="card-title">${item.title}</h3>
                    <button class="icon-btn delete-btn" data-id="${item.id}" aria-label="حذف">
                        <span class="material-icons-round" style="font-size: 20px;">delete_sweep</span>
                    </button>
                </div>
                <p class="card-excerpt">${item.content}</p>
            `;

            card.addEventListener('click', (e) => {
                if (e.target.closest('.delete-btn')) {
                    e.stopPropagation();
                    if(confirm('هل أنت متأكد من حذف هذا العنصر؟')) {
                        deleteItem(section, item.id);
                    }
                } else {
                    openReader(item);
                }
            });
            grid.appendChild(card);
        });
    }

    function renderSettings() {
        grid.innerHTML = `
            <div class="card" style="margin-bottom: 20px;">
                <div class="card-header"><h3 class="card-title">تخصيص المظهر</h3></div>
                <div style="display:flex; justify-content: space-between; align-items:center; margin-top:10px;">
                    <span style="font-weight: 600;">الوضع الليلي</span>
                    <button id="themeToggleBtn" class="icon-btn ${document.body.classList.contains('theme-dark') ? 'primary-bg' : ''}">
                        <span class="material-icons-round">${document.body.classList.contains('theme-dark') ? 'dark_mode' : 'light_mode'}</span>
                    </button>
                </div>
            </div>
            <div class="card">
                <div class="card-header"><h3 class="card-title">عن تطبيق الذاكرين</h3></div>
                <p style="margin-bottom: 15px;">تطبيق إسلامي احترافي يهدف لتوفير تجربة قراءة متميزة للأدعية والزيارات.</p>
                <div style="font-size: 0.9rem; opacity: 0.8;">
                    <p><strong>الإصدار:</strong> 1.0.0 (64-بت)</p>
                    <p><strong>التطوير:</strong> فريق التطوير الاحترافي</p>
                </div>
            </div>
        `;

        document.getElementById('themeToggleBtn').addEventListener('click', function() {
            const isDark = document.body.classList.toggle('theme-dark');
            document.body.classList.toggle('theme-light', !isDark);
            localStorage.setItem('theme', isDark ? 'dark' : 'light');
            this.classList.toggle('primary-bg', isDark);
            this.querySelector('.material-icons-round').textContent = isDark ? 'dark_mode' : 'light_mode';
        });
    }

    // Reader Logic
    function openReader(item) {
        document.getElementById('readerTitle').textContent = item.title;
        document.getElementById('readerText').textContent = item.content;
        readerView.classList.add('active');
        updateFontSize();
    }

    document.getElementById('closeReader').addEventListener('click', () => {
        readerView.classList.remove('active');
    });

    // Font Scaling
    document.getElementById('increaseFont').addEventListener('click', () => {
        if (fontSize < 200) fontSize += 10;
        updateFontSize();
    });

    document.getElementById('decreaseFont').addEventListener('click', () => {
        if (fontSize > 60) fontSize -= 10;
        updateFontSize();
    });

    function updateFontSize() {
        const baseSize = 1.6;
        document.getElementById('readerText').style.fontSize = (fontSize / 100 * baseSize) + 'rem';
        document.getElementById('fontSizeLabel').textContent = fontSize + '%';
    }

    // Add Content Logic
    document.getElementById('addBtn').addEventListener('click', () => {
        if (currentSection === 'settings') {
            alert('يرجى اختيار قسم (أدعية، زيارات، أو ملاحظات) أولاً للإضافة فيه.');
            return;
        }
        const titleMap = {
            'duas': 'إضافة دعاء جديد',
            'visits': 'إضافة زيارة جديدة',
            'notes': 'إضافة ملاحظة جديدة'
        };
        document.getElementById('modalTitle').textContent = titleMap[currentSection] || 'إضافة جديد';
        contentModal.classList.add('active');
        modalOverlay.classList.add('active');
    });

    document.querySelector('.close-modal').addEventListener('click', closeModal);
    modalOverlay.addEventListener('click', closeModal);

    function closeModal() {
        contentModal.classList.remove('active');
        modalOverlay.classList.remove('active');
        document.getElementById('itemTitle').value = '';
        document.getElementById('itemContent').value = '';
    }

    document.getElementById('saveItemBtn').addEventListener('click', () => {
        const title = document.getElementById('itemTitle').value.trim();
        const content = document.getElementById('itemContent').value.trim();

        if (!title || !content) {
            alert('يرجى ملء جميع الحقول المطلوبة.');
            return;
        }

        const newItem = {
            id: Date.now(),
            title,
            content
        };

        if (!data[currentSection]) data[currentSection] = [];
        data[currentSection].unshift(newItem);
        saveData();
        renderSection(currentSection);
        closeModal();
    });

    function deleteItem(section, id) {
        data[section] = data[section].filter(i => i.id !== id);
        saveData();
        renderSection(section);
    }

    function saveData() {
        localStorage.setItem('islamic_app_data', JSON.stringify(data));
    }

    // Search Logic
    searchInput.addEventListener('input', (e) => {
        const term = e.target.value.toLowerCase().trim();
        const cards = grid.querySelectorAll('.card');
        cards.forEach(card => {
            const title = card.querySelector('.card-title').textContent.toLowerCase();
            const excerpt = card.querySelector('.card-excerpt').textContent.toLowerCase();
            card.style.display = (title.includes(term) || excerpt.includes(term)) ? 'block' : 'none';
        });
    });

    // Share & Copy Utility
    document.getElementById('copyBtn').addEventListener('click', () => {
        const text = document.getElementById('readerText').textContent;
        navigator.clipboard.writeText(text).then(() => {
            alert('تم نسخ النص بنجاح');
        });
    });

    document.getElementById('shareBtn').addEventListener('click', async () => {
        const title = document.getElementById('readerTitle').textContent;
        const text = document.getElementById('readerText').textContent;
        if (navigator.share) {
            try {
                await navigator.share({ title, text });
            } catch (err) {
                console.error('Error sharing:', err);
            }
        } else {
            alert('المشاركة غير مدعومة في هذا المتصفح');
        }
    });
});
