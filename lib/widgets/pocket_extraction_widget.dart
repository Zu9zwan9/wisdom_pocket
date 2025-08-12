import 'package:flutter/cupertino.dart';
import 'package:graphx/graphx.dart';
import '../models/quote.dart';
import '../services/quote_repository.dart';

class PocketExtractionWidget extends StatefulWidget {
  final QuoteRepository repository;

  const PocketExtractionWidget({
    super.key,
    required this.repository,
  });

  @override
  State<PocketExtractionWidget> createState() => _PocketExtractionWidgetState();
}

class _PocketExtractionWidgetState extends State<PocketExtractionWidget> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // GraphX сцена без кармана
            SceneBuilderWidget(
              builder: () => SceneController(
                front: PocketExtractionScene(repository: widget.repository),
              ),
              autoSize: true,
            ),
            Center(
              child: Transform.translate(
                offset: const Offset(0, 130),
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/pocket.png',
                    width: 400,
                    height: 266,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PocketExtractionScene extends GSprite {
  final QuoteRepository repository;

  // Константы анимации
  static const double cardWidth = 280.0;
  static const double cardHeight = 180.0;
  static const double pocketOffsetY = 50.0;
  static const double xLimitInPocket = 20.0;
  static const double xLimitOutPocket = 55.0;
  static const double animationDuration = 0.8;
  static const double springBackDuration = 0.5;

  // Компоненты сцены
  late GSprite cardContainer;
  late GSprite card;
  late GSprite pocket;
  late GSprite restartButton;
  late GText restartText;
  late GText quoteText;
  late GText authorText;

  // Состояние карточки
  Quote currentQuote = const Quote(
    id: 0,
    text: 'Loading...',
    author: 'System',
    category: 'system',
  );
  bool isDragging = false;
  bool isCardExtracted = false;
  double initialCardY = 0;
  double cardStartY = 0;

  PocketExtractionScene({required this.repository});

  @override
  void addedToStage() {
    super.addedToStage();
    if (kDebugMode) {
      print('PocketExtractionScene: addedToStage called');
    }
    stage!.onResized.addOnce(_onStageResize);
    _initializeScene();
    _loadNewQuote();
  }

  void _onStageResize() {
    if (kDebugMode) {
      print('Stage resized: ${stage!.stageWidth}x${stage!.stageHeight}');
    }
    _positionElements();
  }

  void _initializeScene() {
    if (kDebugMode) {
      print('Initializing scene...');
    }

    // Создание кармана (должен быть позади карточки)
    _createPocket();

    // Инициализация контейнера карточки
    cardContainer = GSprite();
    addChild(cardContainer);

    // Создание карточки
    _createCard();

    // Создание кнопки перезапуска (скрыта изначально)
    _createRestartButton();

    // Позиционирование элементов
    _positionElements();

    // Настройка обработчиков событий
    _setupEventHandlers();

    if (kDebugMode) {
      print('Scene initialized successfully');
    }
  }

  void _createCard() {
    if (kDebugMode) {
      print('Creating card...');
    }
    card = GSprite();
    cardContainer.addChild(card);

    // Добавляем тень для карточки (iOS-style)
    final shadow = GSprite();
    shadow.graphics
        .clear()
        .beginFill(const Color(0x20000000)) // Полупрозрачная тень
        .drawRoundRect(2, 4, cardWidth, cardHeight, 16, 16)
        .endFill();
    card.addChild(shadow);

    // Основной фон карточки - iOS-style с увеличенным радиусом и без обводки
    card.graphics
        .clear()
        .beginFill(const Color(0xffffffff)) // Чистый белый
        .drawRoundRect(0, 0, cardWidth, cardHeight, 16, 16) // Увеличенный радиус до 16px
        .endFill();

    // Создаем текстовые элементы (используем только базовые свойства GraphX)
    quoteText = GText();
    quoteText.text = 'Loading quote...';
    quoteText.x = 24; // Увеличенные отступы
    quoteText.y = 24;
    quoteText.width = cardWidth - 48;
    quoteText.color = const Color(0xff1c1c1e); // iOS системный цвет текста
    card.addChild(quoteText);

    authorText = GText();
    authorText.text = '- Loading...';
    authorText.x = 24;
    authorText.y = cardHeight - 48; // Больше места снизу
    authorText.width = cardWidth - 48;
    authorText.color = const Color(0xff8e8e93); // iOS вторичный цвет текста
    card.addChild(authorText);

    if (kDebugMode) {
      print('Card created with iOS design');
    }
  }

  void _createPocket() {
    // Карман теперь отображается как Flutter Image виджет
    // Создаем пустой спрайт для совместимости с существующим кодом
    pocket = GSprite();
    addChild(pocket);

    if (kDebugMode) {
      print('Pocket placeholder created (actual pocket is Flutter Image)');
    }
  }

  void _createRestartButton() {
    if (kDebugMode) {
      print('Creating restart button...');
    }
    restartButton = GSprite();

    // Добавляем тень для кнопки (iOS-style)
    final buttonShadow = GSprite();
    buttonShadow.graphics
        .clear()
        .beginFill(const Color(0x15000000)) // Легкая тень
        .drawRoundRect(-68, -23, 136, 46, 23, 23)
        .endFill();
    restartButton.addChild(buttonShadow);

    // Основная кнопка в iOS Blue цвете
    restartButton.graphics
        .clear()
        .beginFill(const Color(0xff007AFF)) // iOS Blue
        .drawRoundRect(-66, -25, 132, 50, 25, 25) // Больший размер, полностью скругленная
        .endFill();

    addChild(restartButton);

    restartText = GText();
    restartText.text = 'Get New Quote';
    restartText.x = -45; // Центрируем текст
    restartText.y = -8;
    restartText.color = const Color(0xffffffff); // Белый текст
    restartButton.addChild(restartText);

    restartButton.mouseEnabled = true;
    restartButton.visible = false;

    if (kDebugMode) {
      print('Restart button created with iOS design');
    }
  }

  void _positionElements() {
    if (stage == null) return;

    final centerX = stage!.stageWidth / 2;
    final centerY = stage!.stageHeight / 2;

    if (kDebugMode) {
      print('Positioning elements at center: $centerX, $centerY');
    }

    // Начальная позиция карточки (наполовину в кармане) - опущена на 30 пикселей
    initialCardY = centerY - cardHeight / 4 + 50; // Добавлены 30 пикселей
    cardStartY = initialCardY;

    cardContainer.x = centerX - cardWidth / 2;
    cardContainer.y = initialCardY;

    // Позиция кармана - опущена на 30 пикселей
    pocket.x = centerX;
    pocket.y = centerY - 50 + 50; // Добавлены 30 пикселей

    // Позиция кнопки перезапуска - также опущена на 30 пикселей
    restartButton.x = centerX;
    restartButton.y = centerY + cardHeight + 100 + 50; // Добавлены 30 пикселей

    if (kDebugMode) {
      print('Elements positioned');
    }
  }

  void _setupEventHandlers() {
    if (kDebugMode) {
      print('Setting up event handlers...');
    }
    cardContainer.mouseEnabled = true;

    cardContainer.onMouseDown.add(_onCardMouseDown);
    stage!.onMouseMove.add(_onMouseMove);
    stage!.onMouseUp.add(_onMouseUp);

    restartButton.onMouseDown.add(_onRestartPressed);

    if (kDebugMode) {
      print('Event handlers set up');
    }
  }

  void _onCardMouseDown(MouseInputData input) {
    if (isCardExtracted) return;

    if (kDebugMode) {
      print('Card mouse down');
    }
    isDragging = true;
    cardStartY = cardContainer.y;
  }

  void _onMouseMove(MouseInputData input) {
    if (!isDragging || isCardExtracted) return;

    final newY = input.stageY - cardHeight / 2;
    final newX = input.stageX - cardWidth / 2;

    // Ограничение движения по Y (можно доставать выше) - увеличен лимит
    if (newY <= cardStartY) {
      cardContainer.y = newY.clamp(cardStartY - cardHeight * 2, cardStartY);
    }

    // Ограничение движения по X в зависимости от положения карточки
    final cardCenterX = stage!.stageWidth / 2 - cardWidth / 2;
    final extractionProgress = (cardStartY - cardContainer.y) / cardHeight;

    // Плавная интерполяция между xLimitInPocket и xLimitOutPocket
    // Интерполяция начинается с extractionProgress = 1.0 и заканчивается на 1.1
    double xLimit;
    if (extractionProgress <= 1.0) {
      xLimit = xLimitInPocket;
    } else if (extractionProgress >= 1.1) {
      xLimit = xLimitOutPocket;
    } else {
      // Линейная интерполяция в диапазоне от 1.0 до 1.1
      final interpolationProgress = (extractionProgress - 1.0) / 0.1; // Нормализуем к диапазону 0-1
      xLimit = xLimitInPocket + (xLimitOutPocket - xLimitInPocket) * interpolationProgress;
    }

    cardContainer.x = (cardCenterX + (newX - cardCenterX))
        .clamp(cardCenterX - xLimit, cardCenterX + xLimit);
  }

  void _onMouseUp(MouseInputData input) {
    if (!isDragging || isCardExtracted) return;

    if (kDebugMode) {
      print('Card mouse up');
    }
    isDragging = false;

    final extractionProgress = (cardStartY - cardContainer.y) / cardHeight;
    if (kDebugMode) {
      print('Extraction progress: $extractionProgress');
    }

    if (extractionProgress >= 0.5) {
      _extractCard();
    } else {
      _returnCardToPocket();
    }

    _centerCardX();
  }

  void _extractCard() {
    if (kDebugMode) {
      print('Extracting card...');
    }
    isCardExtracted = true;

    GTween.to(
      cardContainer,
      animationDuration,
      {'y': cardStartY - cardHeight - 20},
    );

    Future.delayed(Duration(milliseconds: (animationDuration * 1000).toInt()), () {
      _showRestartButton();
    });
  }

  void _showRestartButton() {
    if (kDebugMode) {
      print('Showing restart button');
    }
    restartButton.visible = true;
    restartButton.alpha = 1.0;
  }

  void _returnCardToPocket() {
    if (kDebugMode) {
      print('Returning card to pocket');
    }
    GTween.to(
      cardContainer,
      springBackDuration,
      {'y': cardStartY},
    );
  }

  void _centerCardX() {
    final centerX = stage!.stageWidth / 2 - cardWidth / 2;
    GTween.to(
      cardContainer,
      springBackDuration,
      {'x': centerX},
    );
  }

  void _onRestartPressed(MouseInputData input) {
    if (!isCardExtracted) return;

    if (kDebugMode) {
      print('Restart pressed');
    }

    // Скрыть кнопку
    restartButton.visible = false;
    restartButton.alpha = 0;

    // Сбросить состояние
    isCardExtracted = false;

    // Загрузить новую цитату
    _loadNewQuote();

    // Вернуть карточку в исходное положение
    GTween.to(
      cardContainer,
      animationDuration,
      {
        'y': cardStartY,
        'x': stage!.stageWidth / 2 - cardWidth / 2,
      },
    );
  }

  void _loadNewQuote() {
    if (kDebugMode) {
      print('Loading new quote...');
    }
    try {
      currentQuote = repository.getRandomQuote();
      _updateCardText();
      if (kDebugMode) {
        print('Quote loaded: ${currentQuote.text}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading quote: $e');
      }
      currentQuote = const Quote(
        id: 0,
        text: 'Error loading quote',
        author: 'System',
        category: 'error',
      );
      _updateCardText();
    }
  }

  void _updateCardText() {
    if (kDebugMode) {
      print('Updating card text...');
    }

    // Обновляем текст цитаты
    if (quoteText != null) {
      quoteText.text = currentQuote.text;
    }

    // Обновляем автора
    if (authorText != null) {
      authorText.text = '- ${currentQuote.author}';
    }

    if (kDebugMode) {
      print('Card text updated');
    }
  }
}


const int kColorWhite = 0xffffff;
const int kColorLightGrey = 0xe0e0e0;
const int kColorBrown = 0x8B4513;
const int kColorDarkBrown = 0x654321;
const int kColorGoldenrod = 0xDAA520;
const int kColorGreen = 0x4CAF50;
const int kColorDarkGreen = 0x45a049;
