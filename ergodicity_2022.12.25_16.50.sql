--
-- Скрипт сгенерирован Devart dbForge Studio 2020 for MySQL, Версия 9.0.567.0
-- Домашняя страница продукта: http://www.devart.com/ru/dbforge/mysql/studio
-- Дата скрипта: 25.12.2022 16:50:05
-- Версия сервера: 8.0.25
-- Версия клиента: 4.1
--

-- 
-- Отключение внешних ключей
-- 
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;

-- 
-- Установить режим SQL (SQL mode)
-- 
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- 
-- Установка кодировки, с использованием которой клиент будет посылать запросы на сервер
--
SET NAMES 'utf8mb4';

--
-- Установка базы данных по умолчанию
--
USE ergodicity;

--
-- Удалить процедуру `GameMillions`
--
DROP PROCEDURE IF EXISTS GameMillions;

--
-- Удалить процедуру `GameSwitchRoles`
--
DROP PROCEDURE IF EXISTS GameSwitchRoles;

--
-- Удалить процедуру `GameToTheEnd`
--
DROP PROCEDURE IF EXISTS GameToTheEnd;

--
-- Удалить таблицу `game1`
--
DROP TABLE IF EXISTS game1;

--
-- Удалить таблицу `game2`
--
DROP TABLE IF EXISTS game2;

--
-- Установка базы данных по умолчанию
--
USE ergodicity;

--
-- Создать таблицу `game2`
--
CREATE TABLE game2 (
  id INT NOT NULL AUTO_INCREMENT,
  dt TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  Start_SummaCasino DOUBLE DEFAULT NULL,
  Start_SummaPlayer DOUBLE DEFAULT NULL,
  Start_PartOfMoneyPlayerForOneBet DOUBLE DEFAULT NULL,
  Start_PlayerChanceToWin DOUBLE DEFAULT NULL,
  Start_CountGames INT DEFAULT NULL,
  End_BetCount INT DEFAULT NULL,
  End_WhoWin CHAR(1) DEFAULT NULL,
  End_SummaCasino DOUBLE DEFAULT NULL,
  End_SummaPlayer DOUBLE DEFAULT NULL,
  PRIMARY KEY (id)
)
ENGINE = INNODB,
AUTO_INCREMENT = 1766,
AVG_ROW_LENGTH = 174,
CHARACTER SET utf8mb4,
COLLATE utf8mb4_0900_ai_ci;

--
-- Создать таблицу `game1`
--
CREATE TABLE game1 (
  id INT NOT NULL AUTO_INCREMENT,
  id_game2 INT DEFAULT NULL,
  dt TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  Start_SummaCasino_Start DOUBLE DEFAULT NULL,
  Start_SummaPlayer DOUBLE DEFAULT NULL,
  Start_PartOfMoneyPlayerForOneBet DOUBLE DEFAULT NULL,
  Start_PlayerChanceToWin DOUBLE DEFAULT NULL,
  End_BetCount INT DEFAULT NULL,
  End_WhoWin CHAR(1) DEFAULT NULL,
  End_SummaCasino DOUBLE DEFAULT NULL,
  End_SummaPlayer DOUBLE DEFAULT NULL,
  PRIMARY KEY (id)
)
ENGINE = INNODB,
AUTO_INCREMENT = 57856,
AVG_ROW_LENGTH = 239,
CHARACTER SET utf8mb4,
COLLATE utf8mb4_0900_ai_ci;

--
-- Создать внешний ключ
--
ALTER TABLE game1 
  ADD CONSTRAINT FK_game1_id_game2 FOREIGN KEY (id_game2)
    REFERENCES game2(id) ON DELETE CASCADE;

DELIMITER $$

--
-- Создать процедуру `GameToTheEnd`
--
CREATE 
	DEFINER = 'root'@'localhost'
PROCEDURE GameToTheEnd(IN _id_game2 INT, INOUT v_SummaCasino DOUBLE, INOUT v_SummaPlayer DOUBLE, IN v_PartOfMoneyPlayerForOneBet DOUBLE, IN v_PlayerChanceToWin DOUBLE)
BEGIN

  # Процедура эмулирующая игру между игроком и казино
  # Игрок играет "до последнего" цента - пока проиграет всё либо игрок, либо разорится казино.
  # Игрок всегда делает ставку равную заданной части от оставшеймся у него суммы.

  # Логируем в таблицу "game1"

  # Казино играет честно, с математическим ожиданием выигрыша 50%
  # При этом в игре казино определяет шанс на выигрыш посетителя.
  # Если шанс на выигрыш меньше, то сумма пропорционально больше.
  # Если шанс на выигрыш больше, то сумма пропорционально меньше.
  # Например, если игрок делает ставку 100 долларов:
  #   при шансах игрока 50%, казино поставит 100 $;
  #   при шансах игрока 25%, казино поставит 300 $;
  #   при шансах игрока 10%, казино поставит 900 $;
  #   и так далее
  #   при шансах игрока 66,6666%, казино поставит 50 $;

  # _id_game2                     = № игры под которой будет логгироваться игра.
  # v_SummaCasino                 = Стартовая сумма денег в казино
  # v_SummaPlayer                 = Стартовая сумма денег у игрока
  # v_PartOfMoneyPlayerForOneBet  = Часть денег игрока, которой он делает одну ставку  (от 0 до 1)
  # v_PlayerChanceToWin           = Шанс выигрыша игрока (от 0 до 1)

  DECLARE _id_GameToTheEnd int;
  DECLARE _SummaPlayerInsignificant double;
  DECLARE _SummaCasinoInsignificant double;
  DECLARE _SummaPlayerStart double;
  DECLARE _BetCount int;
  DECLARE _Bet double;
  DECLARE _Pay double;
  DECLARE _BetWinner char;
  DECLARE _BetCountLimit INT;

  # Логгирую новую игру
  INSERT INTO game1(id_game2, Start_SummaCasino_Start, Start_SummaPlayer, Start_PartOfMoneyPlayerForOneBet, Start_PlayerChanceToWin)
  VALUES (_id_game2, v_SummaCasino, v_SummaPlayer, v_PartOfMoneyPlayerForOneBet, v_PlayerChanceToWin);

  # Вытаскиваю вставленный ID
  SELECT @@last_insert_id 
  INTO _id_GameToTheEnd;

  # Цикл ставок одной игры
  SET _BetCount = 0;
  SET _BetCountLimit = 2000;
  SET _SummaPlayerStart = v_SummaPlayer;
  SET _SummaPlayerInsignificant = v_SummaPlayer * 0.000001;
  SET _SummaCasinoInsignificant = v_SummaCasino * 0.000001;
  WHILE (_BetCount<_BetCountLimit) 
  AND (v_SummaCasino>_SummaCasinoInsignificant)
  AND (v_SummaPlayer>_SummaPlayerInsignificant)
  DO

    # Номер ставки
    SET _BetCount = _BetCount + 1;

    # Рассчитываю ставку игрока
    SET _Bet = v_SummaPlayer * v_PartOfMoneyPlayerForOneBet;
    SET _Bet = IF(v_SummaPlayer<2*_SummaPlayerInsignificant, v_SummaPlayer, _Bet); # Если остаются копейки, то их все берём в игру

    # Рассчитываю ставку казино
    SET _Pay = _Bet / v_PlayerChanceToWin - _Bet;
    SET _Pay = LEAST( _Pay, v_SummaCasino );

    # Если казино уже не может поддержать ставку игрока, то уменьшаю ставку игрока
    SET _Bet = LEAST( _Bet , _Pay / (1-v_PlayerChanceToWin) - _Pay );

    # Кто победил
    SET _BetWinner = IF(RAND() < v_PlayerChanceToWin, 'P', 'C');

    # Перевод денег победителю
    IF (_BetWinner='P') THEN
      SET v_SummaCasino = v_SummaCasino - _Pay;
      SET v_SummaPlayer = v_SummaPlayer + _Pay;
    ELSE
      SET v_SummaCasino = v_SummaCasino + _Bet;
      SET v_SummaPlayer = v_SummaPlayer - _Bet;
    END IF;

  END WHILE;
  
  # Логгирую результат
  UPDATE game1
  SET End_BetCount = _BetCount
    , End_WhoWin = IF(v_SummaPlayer>=_SummaPlayerStart,'P','C')
    , End_SummaCasino = v_SummaCasino
    , End_SummaPlayer = v_SummaPlayer
  WHERE id = _id_GameToTheEnd;

END
$$

--
-- Создать процедуру `GameSwitchRoles`
--
CREATE 
	DEFINER = 'root'@'localhost'
PROCEDURE GameSwitchRoles(
  IN v_SummaCasino DOUBLE
, IN v_SummaPlayer DOUBLE
, IN v_PartOfMoneyPlayerForOneBet DOUBLE
, IN v_PlayerChanceToWin DOUBLE
, IN v_CountGames INT)
BEGIN

  # Игрок представляет,
  # что у казино намного меньше денег,
  # и это казино делает ставки у игрока.

  # Таким образом Игрок меняются местами с Казино,
  # вызывая процедуру игры "GameToTheEnd" с аргументами наоборот.

  # Логируем в таблицу "game2"

  DECLARE _PartMoneyCasinoForOneGame2 double;
  DECLARE _SummaPlayerInsignificant double;
  DECLARE _SummaCasinoInsignificant double;
  DECLARE _id_Game2 double;
  DECLARE _BetCount int;
  DECLARE _Game1_SummaCasino double;
  DECLARE _Game1_SummaPlayer double;
  DECLARE _SummaPlayerStart double;
  DECLARE _BetWinner char;

  DECLARE _A double;
  DECLARE _B double;

  # Логгирую новую игру
  INSERT INTO game2(Start_SummaCasino, Start_SummaPlayer, Start_PartOfMoneyPlayerForOneBet, Start_PlayerChanceToWin, Start_CountGames)
  VALUES (v_SummaCasino, v_SummaPlayer, v_PartOfMoneyPlayerForOneBet, v_PlayerChanceToWin, v_CountGames);

  # Вытаскиваю вставленный ID
  SELECT @@last_insert_id 
  INTO _id_Game2;

  # Цикл игр, в которых мы заставим казино исполнять роль игрока
  SET _BetCount = 0;
  SET _SummaPlayerStart = v_SummaPlayer;
  SET _SummaPlayerInsignificant = v_SummaPlayer * 0.000001;
  SET _SummaCasinoInsignificant = v_SummaCasino * 0.000001;

  # Цикл игр уровня 2
  WHILE (_BetCount<v_CountGames) 
  AND (v_SummaCasino>_SummaCasinoInsignificant)
  AND (v_SummaPlayer>_SummaPlayerInsignificant)
  DO

    # Номер ставки
    SET _BetCount = _BetCount + 1;

    # Определяю параметры на одну игру
    SET _Game1_SummaPlayer = (_SummaPlayerStart / v_CountGames);

    SET _A = ((_BetCount-1)*(_SummaPlayerStart/(v_CountGames)));
    SET _B = (v_SummaPlayer-_SummaPlayerStart);

    SET _Game1_SummaPlayer = _Game1_SummaPlayer + _A - _B;

    SET _Game1_SummaCasino = v_SummaPlayer;

    # Вычитаю деньги со счетов сторон
    SET v_SummaCasino = v_SummaCasino - _Game1_SummaPlayer;
    SET v_SummaPlayer = v_SummaPlayer - _Game1_SummaCasino;

    # Провожу "Игру-1", где стороны поменялись ролями
    CALL GameToTheEnd( _id_Game2, _Game1_SummaCasino, _Game1_SummaPlayer, v_PartOfMoneyPlayerForOneBet, 1-v_PlayerChanceToWin );

    # Возвращаю деньги на счета сторон после проведения игра-1
    SET v_SummaCasino = v_SummaCasino + _Game1_SummaPlayer;
    SET v_SummaPlayer = v_SummaPlayer + _Game1_SummaCasino;

  END WHILE;

  # Определяю результат
  SET _BetWinner = IF(v_SummaPlayer>=_SummaPlayerStart,'P','C');

  # Логгирую результат
  UPDATE game2
  SET End_BetCount = _BetCount
    , End_WhoWin = _BetWinner
    , End_SummaCasino = v_SummaCasino
    , End_SummaPlayer = v_SummaPlayer
  WHERE id = _id_Game2;

END
$$

--
-- Создать процедуру `GameMillions`
--
CREATE 
	DEFINER = 'root'@'localhost'
PROCEDURE GameMillions()
BEGIN

  # Много раз проворачиваем игру "GameSwitchRoles",
  # где игрок поменялся местами с казино

  DECLARE N INT;
  DECLARE _dt_start INT;

  # Засекаю время начала расчёта
  SELECT UNIX_TIMESTAMP(NOW()) INTO _dt_start;

  # Очищаю данные прошлого расчёта
  DELETE FROM game1;
  DELETE FROM game2;

  # Цикл повтора игр
  SET N = 0;
  WHILE (N<100) DO
    SET N=N+1;
    CALL GameSwitchRoles( 1000000, 50000, 0.2, 0.75, 100 );
  END WHILE;

  # Вывожу статистику по результатам симуляций
  SELECT CONCAT('Итого игрок выигрывал у казино в ', (100*SUM(End_WhoWin='C')/COUNT(1)), ' процентах случаев.') AS itog
       , CONCAT('Расчёт занял ', (UNIX_TIMESTAMP(NOW())-_dt_start), ' секунд.') as time
  FROM game2;

END
$$

DELIMITER ;

-- 
-- Вывод данных для таблицы game2
--
-- Таблица ergodicity.game2 не содержит данных

-- 
-- Вывод данных для таблицы game1
--
-- Таблица ergodicity.game1 не содержит данных

-- 
-- Восстановить предыдущий режим SQL (SQL mode)
--
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;

-- 
-- Включение внешних ключей
-- 
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;