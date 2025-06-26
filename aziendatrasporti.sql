-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3310
-- Creato il: Giu 26, 2025 alle 08:26
-- Versione del server: 10.4.32-MariaDB
-- Versione PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `aziendatrasporti`
--

-- --------------------------------------------------------

--
-- Struttura della tabella `abbonamenti`
--

CREATE TABLE `abbonamenti` (
  `IDBiglietto` int(11) NOT NULL,
  `DataInizio` date NOT NULL,
  `DataFine` date NOT NULL,
  `TipoAbbonamento` enum('Mensile','Annuale','Settimanale') NOT NULL,
  `Tariffa_Abbonato` enum('35','90','800') NOT NULL,
  `IDAbbonato` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `abbonamenti`
--

INSERT INTO `abbonamenti` (`IDBiglietto`, `DataInizio`, `DataFine`, `TipoAbbonamento`, `Tariffa_Abbonato`, `IDAbbonato`) VALUES
(5, '2025-01-02', '2025-02-02', 'Mensile', '90', 1),
(6, '2025-06-06', '2026-06-06', 'Annuale', '800', 2),
(7, '2025-06-17', '2025-06-24', 'Settimanale', '35', 3);

--
-- Trigger `abbonamenti`
--
DELIMITER $$
CREATE TRIGGER `controllo_durata_abbonamento` BEFORE INSERT ON `abbonamenti` FOR EACH ROW BEGIN
    DECLARE intervallo INT;
    SET intervallo = DATEDIFF(NEW.DataFine, NEW.DataInizio);
-- se Data Fine è precedente a Data Inizio
    IF NEW.DataFine < NEW.DataInizio THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: la data di fine non può essere precedente alla data di inizio.';
    END IF;
-- Controllo abbonamento settimanale
    IF NEW.TipoAbbonamento = 'Settimanale' AND intervallo != 7 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: durata abbonamento settimanale deve essere esattamente 7 giorni.';
    END IF;
-- Controllo abbonamento mensile
    IF NEW.TipoAbbonamento = 'Mensile' AND (intervallo < 27 OR intervallo > 31) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: durata mensile deve essere tra 27 e 31 giorni.';
    END IF;
-- Controllo abbonamento annuale
    IF NEW.TipoAbbonamento = 'Annuale' AND intervallo != 365 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Errore: durata annuale deve essere deve essere esattamente di 365 giorni.';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `controllo_stato_Biglietto` BEFORE INSERT ON `abbonamenti` FOR EACH ROW BEGIN
  DECLARE stato_biglietto VARCHAR(20);

  -- Recupera lo stato del biglietto collegato
  SELECT Stato INTO stato_biglietto
  FROM biglietti
  WHERE ID = NEW.IDBiglietto;

  -- Se lo stato non è valido, blocca
  IF stato_biglietto NOT IN ('Attivo', 'Scaduto') THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Errore: lo stato del biglietto non è valido per un abbonamento, deve essere Attivo o Scaduto).';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `controllo_tariffa` BEFORE INSERT ON `abbonamenti` FOR EACH ROW BEGIN
  -- Verifica se la tariffa corrisponde al tipo di abbonamento
  IF NEW.TipoAbbonamento = 'Settimanale' AND NEW.tariffa_abbonato != '35' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'La tariffa per un abbonamento settimanale deve essere 35.';
  ELSEIF NEW.TipoAbbonamento = 'Mensile' AND NEW.tariffa_abbonato != '90' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'La tariffa per un abbonamento mensile deve essere 90.';
  ELSEIF NEW.TipoAbbonamento = 'Annuale' AND NEW.tariffa_abbonato != '800' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'La tariffa per un abbonamento annuale deve essere 800.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `abbonati`
--

CREATE TABLE `abbonati` (
  `IDAbbonato` int(11) NOT NULL,
  `CFAbbonato` char(16) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `abbonati`
--

INSERT INTO `abbonati` (`IDAbbonato`, `CFAbbonato`) VALUES
(1, 'BNCGLI88S43H501W'),
(2, 'DMTLCU00R10H501W'),
(3, 'VRDLSN92H27L219R');

--
-- Trigger `abbonati`
--
DELIMITER $$
CREATE TRIGGER `controllo_CF_abbonato` BEFORE INSERT ON `abbonati` FOR EACH ROW BEGIN
  -- Controlla se lo stesso CF esiste già in occasionale
  IF EXISTS (
    SELECT 1 
    FROM occasionali
    WHERE CFOccasionali = NEW.CFAbbonato
  ) -- Se è presente il CF in occasionali
  THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Errore: Questo passeggero è già registrato come occasionale.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `biglietti`
--

CREATE TABLE `biglietti` (
  `ID` int(11) NOT NULL,
  `Stato` enum('Attivo','Scaduto','Rimborsato','Usato') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `biglietti`
--

INSERT INTO `biglietti` (`ID`, `Stato`) VALUES
(1, 'Usato'),
(2, 'Rimborsato'),
(3, 'Usato'),
(4, 'Attivo'),
(5, 'Attivo'),
(6, 'Scaduto'),
(7, 'Attivo'),
(8, 'Usato'),
(9, 'Scaduto');

-- --------------------------------------------------------

--
-- Struttura della tabella `dettaglio_viaggi`
--

CREATE TABLE `dettaglio_viaggi` (
  `CodMezzo` int(11) NOT NULL,
  `IDBiglietto` int(11) NOT NULL,
  `Posto` varchar(3) NOT NULL,
  `Convalida` enum('SI','NO') NOT NULL,
  `Classe` int(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `dettaglio_viaggi`
--

INSERT INTO `dettaglio_viaggi` (`CodMezzo`, `IDBiglietto`, `Posto`, `Convalida`, `Classe`) VALUES
(2, 1, '25E', 'SI', 2),
(2, 7, '4A', 'SI', 2),
(5, 5, '10B', 'SI', 2),
(7, 8, '14E', 'SI', 2),
(8, 3, '14E', 'NO', 2),
(9, 3, '16B', 'NO', 2);

--
-- Trigger `dettaglio_viaggi`
--
DELIMITER $$
CREATE TRIGGER `controllo_aggiornamento` AFTER INSERT ON `dettaglio_viaggi` FOR EACH ROW BEGIN
    -- Controlla se il biglietto inserito in dettaglio_viaggi è di tipo Standard
    IF EXISTS (
        SELECT 1 FROM standard WHERE IDBiglietto = NEW.IDBiglietto
    ) THEN
        -- Aggiorna lo stato in BIGLIETTI da Attivo a Usato
        UPDATE biglietti
        SET Stato = 'Usato'
        WHERE ID = NEW.IDBiglietto
          AND Stato = 'Attivo';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `controllo_andata_ritorno` BEFORE INSERT ON `dettaglio_viaggi` FOR EACH ROW BEGIN
  DECLARE scelta ENUM('Andata', 'Andata_Ritorno');
  DECLARE conteggio INT DEFAULT 0;

  -- Prendi la scelta dal biglietto standard
  SELECT s.Scelta INTO scelta
  FROM standard s
  JOIN biglietti b ON b.ID = s.IDBiglietto
  WHERE b.ID = NEW.IDBiglietto;

  -- Conta quanti dettagli viaggio ci sono già per quel biglietto
  SELECT COUNT(*) INTO conteggio
  FROM dettaglio_viaggi
  WHERE IDBiglietto = NEW.IDBiglietto;

  -- Se scelta = Andata e ci sono già 1 o più, blocca
  IF scelta = 'Andata' AND conteggio = 1 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Errore: un biglietto di sola Andata può avere solo un viaggio.';
  END IF;

  -- Se scelta = AndataRitorno e già 2 o più, blocca
  IF scelta = 'Andata_Ritorno' AND conteggio = 2 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Errore: un biglietto Andata/Ritorno può avere al massimo due viaggi.';
  END IF;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `controllo_convalida` BEFORE INSERT ON `dettaglio_viaggi` FOR EACH ROW BEGIN
  DECLARE isAbbonamento INT DEFAULT 0;

  -- Controlla se esiste una riga in Abbonamento per questo biglietto
  SELECT COUNT(*) INTO isAbbonamento
  FROM abbonamenti
  WHERE IdBiglietto = NEW.IDBiglietto;

  -- Se è abbonamento e Convalida = 'NO', blocca
  IF isAbbonamento = 1 AND NEW.Convalida = 'NO' THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Errore: Un abbonamento non può avere Convalida = NO.';
  END IF;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `controllo_posto_univoco` BEFORE INSERT ON `dettaglio_viaggi` FOR EACH ROW BEGIN
  DECLARE duplicato INT;

  -- Verifica se esiste già un record con stesso CodMezzo, stesso posto e stessa Data
  SELECT COUNT(*)
  INTO duplicato
  FROM dettaglio_viaggi
  WHERE CodMezzo = NEW.CodMezzo
    AND Posto = NEW.Posto
    AND Classe= NEW.Classe;
  -- Se esiste almeno uno, blocca l'inserimento
  IF duplicato > 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Errore: Posto già assegnato per questa tratta e data.';
  END IF;

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `controllo_standard` BEFORE INSERT ON `dettaglio_viaggi` FOR EACH ROW BEGIN
  DECLARE stato_biglietto ENUM('Attivo','Scaduto','Rimborsato','Usato');

  -- Recupera lo stato del biglietto legato al dettaglio viaggio
  SELECT Stato INTO stato_biglietto
  FROM biglietti
  WHERE ID = NEW.IDBiglietto;

  -- Se è Rimborsato, blocca
   IF stato_biglietto IN ('Rimborsato', 'Usato','Scaduto') THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Errore: Non è possibile aggiungere un dettaglio viaggio per un biglietto rimborsato, già usato o scaduto.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `disponib_tratte`
--

CREATE TABLE `disponib_tratte` (
  `ID` int(11) NOT NULL,
  `Data` date NOT NULL,
  `PostiDisp` int(3) NOT NULL,
  `IDTratta` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `disponib_tratte`
--

INSERT INTO `disponib_tratte` (`ID`, `Data`, `PostiDisp`, `IDTratta`) VALUES
(1, '2025-05-25', 2, 8),
(2, '2025-06-21', 0, 2),
(3, '2025-12-01', 4, 1),
(4, '2025-05-06', 2, 6),
(5, '2025-06-01', 0, 5),
(6, '2025-08-15', 1, 4),
(7, '2025-12-31', 7, 3),
(8, '2025-05-26', 2, 9),
(9, '2025-05-10', 5, 7);

--
-- Trigger `disponib_tratte`
--
DELIMITER $$
CREATE TRIGGER `controllo_numero_posti` BEFORE INSERT ON `disponib_tratte` FOR EACH ROW BEGIN
  IF NEW.PostiDisp < 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Non è possibile inserire un numero di posti disponibili inferiore a zero.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `fermate`
--

CREATE TABLE `fermate` (
  `NomeStazione` varchar(30) NOT NULL,
  `OraArrivo` time DEFAULT NULL,
  `OraPartenza` time DEFAULT NULL,
  `Tipo` enum('Partenza','Scalo','Intermedia','Tecnica','Destinazione') NOT NULL,
  `Binario` int(2) NOT NULL,
  `CodMezzo` int(11) NOT NULL,
  `IDTratta` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `fermate`
--

INSERT INTO `fermate` (`NomeStazione`, `OraArrivo`, `OraPartenza`, `Tipo`, `Binario`, `CodMezzo`, `IDTratta`) VALUES
('Latina', '10:18:00', '10:15:00', 'Intermedia', 2, 5, 3),
('Pomezia', '10:25:00', '11:00:00', 'Tecnica', 1, 5, 3),
('Roma Termini', '00:00:00', '00:00:00', 'Destinazione', 3, 5, 3),
('Formia', '10:10:00', '10:00:00', 'Partenza', 5, 5, 3),
('Napoli Centrale', '05:50:00', '05:10:00', 'Partenza', 3, 6, 2),
('Salerno', '07:50:00', '05:55:00', 'Scalo', 10, 6, 2),
('Lamezia Terme', '08:05:00', '08:00:00', 'Intermedia', 5, 6, 2),
('Reggio Calabria', '00:00:00', '00:00:00', 'Destinazione', 12, 6, 2),
('Roma Termini', '15:50:00', '15:40:00', 'Partenza', 3, 1, 6),
('Roma Tiburtina', '16:00:00', '15:55:00', 'Tecnica', 6, 1, 6),
('Cassino', '16:30:00', '16:20:00', 'Intermedia', 8, 1, 6),
('Aversa', '17:20:00', '16:58:00', 'Scalo', 3, 1, 6),
('Napoli Centrale', '00:00:00', '00:00:00', 'Destinazione', 1, 1, 6),
('Palermo', '19:00:00', '14:00:00', 'Partenza', 5, 3, 8),
('Catania', '00:00:00', '00:00:00', 'Destinazione', 2, 3, 8),
('Milano', '20:00:00', '15:50:00', 'Partenza', 6, 2, 1),
('Roma Termini', '00:00:00', '00:00:00', 'Destinazione', 4, 2, 1),
('Verona Porta Nuova', '12:35:00', '12:00:00', 'Partenza', 9, 7, 7),
('Rovereto', '13:10:00', '12:40:00', 'Intermedia', 2, 7, 7),
('Trento', '00:00:00', '00:00:00', 'Destinazione', 3, 7, 7),
('Genova Brignole', '09:30:00', '09:10:00', 'Partenza', 5, 4, 5),
('Genova Piazza principale', '10:35:00', '09:35:00', 'Intermedia', 3, 4, 5),
('La Spezia Centrale', '00:00:00', '00:00:00', 'Destinazione', 1, 4, 5),
('Catania', '13:00:00', '08:00:00', 'Partenza', 3, 9, 9),
('Palermo', NULL, NULL, 'Destinazione', 3, 5, 9);

--
-- Trigger `fermate`
--
DELIMITER $$
CREATE TRIGGER `controllo_orario_fermata` BEFORE INSERT ON `fermate` FOR EACH ROW BEGIN
  
  -- Se è una fermata di destinazione, OrarioPartenza deve essere NULL
IF NEW.Tipo = 'destinazione' AND NEW.OraPartenza IS NOT NULL AND NEW.OraArrivo IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Una fermata di destinazione non può avere un orario di partenza o di arrivo.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `occasionali`
--

CREATE TABLE `occasionali` (
  `CFOccasionale` char(16) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `occasionali`
--

INSERT INTO `occasionali` (`CFOccasionale`) VALUES
('CNTLNE00P55D612Q'),
('RSSMRC95D12F205X'),
('SRRGLR96T41H501Z');

--
-- Trigger `occasionali`
--
DELIMITER $$
CREATE TRIGGER `controllo_CF_occasionale` BEFORE INSERT ON `occasionali` FOR EACH ROW BEGIN
  -- Controlla se esiste già lo stesso CF in abbonato
  IF EXISTS (
    SELECT 1 
    FROM abbonati
    WHERE CFAbbonato = NEW.CFOccasionale
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Errore: Questo passeggero è già registrato come abbonato.';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `passeggeri`
--

CREATE TABLE `passeggeri` (
  `CF` char(16) NOT NULL,
  `Nome` varchar(30) NOT NULL,
  `Cognome` varchar(30) NOT NULL,
  `DataNascita` date NOT NULL,
  `NumTelefono` varchar(15) NOT NULL,
  `Email` varchar(50) NOT NULL,
  `Sesso` enum('M','F') NOT NULL,
  `MetodoPag` varchar(20) NOT NULL,
  `Indirizzo` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `passeggeri`
--

INSERT INTO `passeggeri` (`CF`, `Nome`, `Cognome`, `DataNascita`, `NumTelefono`, `Email`, `Sesso`, `MetodoPag`, `Indirizzo`) VALUES
('BNCGLI88S43H501W', 'Giulia', 'Bianchi', '1988-11-03', '4567890123', 'giuliabianchi88@gmail.com', 'F', 'bonifico bancario', 'Via Manca 10, Cagliari'),
('CNTLNE00P55D612Q', 'Elena', 'Conti', '2000-05-15', '2147483647', 'elenaconti10@live.it', 'F', 'carta di credito', 'Via Milano 15, Bari'),
('DMTLCU00R10H501W', 'Luca ', 'Di Matteo', '2000-10-10', '7890123456', 'lucadimatteo1010@gmail.com', 'M', 'bonifico bancario', 'Via Giuseppe Garibaldi 31, Napoli'),
('RSSMRC95D12F205X', 'Marco', 'Rossi', '1995-04-12', '1234567890', 'mariorossi1@gmail.com', 'M', 'contante', 'Via Alcide De Gasperi 20, Roma'),
('SRRGLR96T41H501Z', 'Gloria ', 'Serra', '1996-12-01', '492813812', 'gloria.serra@hotmail.it', 'F', 'contante ', 'Via Mazzini 1, Sassari'),
('VRDLSN92H27L219R', 'Alessandro', 'Verdi', '1992-06-27', '3456789012', 'alessandroverdi@outlook.it', 'M', 'carta di credito', 'Via Settembre 16, Treviso');

-- --------------------------------------------------------

--
-- Struttura della tabella `prenotazioni`
--

CREATE TABLE `prenotazioni` (
  `ID` int(11) NOT NULL,
  `DataPren` datetime NOT NULL,
  `CFpasseggero` char(16) NOT NULL,
  `IDdisp_Tratta` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `prenotazioni`
--

INSERT INTO `prenotazioni` (`ID`, `DataPren`, `CFpasseggero`, `IDdisp_Tratta`) VALUES
(1, '2025-05-20 17:02:00', 'CNTLNE00P55D612Q', 1),
(2, '2025-04-20 10:45:00', 'CNTLNE00P55D612Q', 8),
(3, '2025-11-10 09:10:00', 'RSSMRC95D12F205X', 3),
(4, '2025-04-02 21:45:00', 'RSSMRC95D12F205X', 4),
(5, '2025-06-21 11:46:42', 'SRRGLR96T41H501Z', 7);

--
-- Trigger `prenotazioni`
--
DELIMITER $$
CREATE TRIGGER `controllo_data_prenotazione` BEFORE INSERT ON `prenotazioni` FOR EACH ROW BEGIN
  DECLARE data_tratta DATE;

  -- Prende la data disponibile per la tratta prenotata
  SELECT Data INTO data_tratta
  FROM disponib_tratte
  WHERE ID = NEW.IDdisp_Tratta;

  -- Controlla che la data della prenotazione non sia successiva
  IF NEW.DataPren > data_tratta THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'La data della prenotazione non può essere successiva alla data della tratta selezionata.';
  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `controllo_posti_disponibili` BEFORE INSERT ON `prenotazioni` FOR EACH ROW BEGIN
  DECLARE posti INT;

  -- Controllo dei posti disponibili
  SELECT PostiDisp INTO posti
  FROM disponib_tratte
  WHERE ID = NEW.IDdisp_Tratta;

  -- Se non ci sono posti, blocca l'inserimento
  IF posti IS NULL OR posti <= 0 THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Mi dispiace, nessun posto disponibile per questa tratta e data.';
  ELSE
    -- Decrementa i posti disponibili
    UPDATE disponib_tratte
    SET PostiDisp = PostiDisp - 1
    WHERE ID = NEW.IDdisp_Tratta;
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `standard`
--

CREATE TABLE `standard` (
  `IDBiglietto` int(11) NOT NULL,
  `Prezzo` decimal(6,2) NOT NULL,
  `Rimborsabile` enum('SI','NO') NOT NULL,
  `Scelta` enum('Andata','Andata_Ritorno') NOT NULL,
  `IDPrenotazione` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `standard`
--

INSERT INTO `standard` (`IDBiglietto`, `Prezzo`, `Rimborsabile`, `Scelta`, `IDPrenotazione`) VALUES
(1, 20.90, 'SI', 'Andata', 4),
(2, 10.50, 'NO', 'Andata', 3),
(3, 18.90, 'SI', 'Andata_Ritorno', 1),
(4, 15.50, 'SI', 'Andata', 2),
(8, 19.00, 'NO', 'Andata', 5);

--
-- Trigger `standard`
--
DELIMITER $$
CREATE TRIGGER `controllo_rimborso` BEFORE UPDATE ON `standard` FOR EACH ROW BEGIN
  -- Se sto impostando Rimborsabile a 'NO'
  IF NEW.Rimborsabile = 'NO' THEN
    -- Controlla se in biglietti è già Rimborsato
    IF EXISTS (
      SELECT 1
      FROM biglietti
      WHERE ID = NEW.IDBiglietto AND Stato = 'Rimborsato'
    ) THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Errore: non puoi impostare Rimborsabile a NO se il biglietto è già Rimborsato.';
    END IF;
  END IF;

  -- Se lo stato in biglietti è Scaduto allora Rimborsabile deve essere NO
  IF EXISTS (
    SELECT 1
    FROM biglietti
    WHERE ID = NEW.IDBiglietto AND Stato = 'Scaduto'
  ) THEN
    IF NEW.Rimborsabile <> 'NO' THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Errore: se lo stato è Scaduto, il biglietto non può essere rimborsabile.';
    END IF;
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `tratte`
--

CREATE TABLE `tratte` (
  `ID` int(11) NOT NULL,
  `Nome` varchar(30) NOT NULL,
  `TipoServizio` varchar(15) NOT NULL,
  `DistanzaKM` int(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `tratte`
--

INSERT INTO `tratte` (`ID`, `Nome`, `TipoServizio`, `DistanzaKM`) VALUES
(1, 'Milano-Roma', 'diretto', 570),
(2, 'Napoli-Reggio', 'intercity', 449),
(3, 'Formia-Roma', 'regionale', 168),
(4, 'Torino-Firenze', 'alta velocità', 450),
(5, 'Genova-La Spezia', 'regionale', 95),
(6, 'Roma-Napoli', 'alta velocità', 230),
(7, 'Verona-Trento', 'regionale', 90),
(8, 'Palermo-Catania', 'diretto', 220),
(9, 'Catania-Palermo', 'diretto', 220);

-- --------------------------------------------------------

--
-- Struttura della tabella `viaggi`
--

CREATE TABLE `viaggi` (
  `IDmezzo` int(11) NOT NULL,
  `Stato` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dump dei dati per la tabella `viaggi`
--

INSERT INTO `viaggi` (`IDmezzo`, `Stato`) VALUES
(1, 'in partenza'),
(2, 'programmato'),
(3, 'in ritardo'),
(4, 'in partenza'),
(5, 'completato'),
(6, 'in partenza'),
(7, 'completato'),
(8, 'in corso'),
(9, 'in corso');

--
-- Indici per le tabelle scaricate
--

--
-- Indici per le tabelle `abbonamenti`
--
ALTER TABLE `abbonamenti`
  ADD PRIMARY KEY (`IDBiglietto`),
  ADD KEY `IDAbbonato` (`IDAbbonato`),
  ADD KEY `TipoAbbonamento` (`TipoAbbonamento`),
  ADD KEY `DataFine` (`DataFine`);

--
-- Indici per le tabelle `abbonati`
--
ALTER TABLE `abbonati`
  ADD PRIMARY KEY (`IDAbbonato`),
  ADD UNIQUE KEY `CF` (`CFAbbonato`) USING BTREE;

--
-- Indici per le tabelle `biglietti`
--
ALTER TABLE `biglietti`
  ADD PRIMARY KEY (`ID`);

--
-- Indici per le tabelle `dettaglio_viaggi`
--
ALTER TABLE `dettaglio_viaggi`
  ADD PRIMARY KEY (`CodMezzo`,`IDBiglietto`),
  ADD KEY `CodMezzo` (`CodMezzo`),
  ADD KEY `IdBiglietto` (`IDBiglietto`) USING BTREE;

--
-- Indici per le tabelle `disponib_tratte`
--
ALTER TABLE `disponib_tratte`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `IDTratta` (`IDTratta`),
  ADD KEY `Data_Disponibilità` (`Data`);

--
-- Indici per le tabelle `fermate`
--
ALTER TABLE `fermate`
  ADD KEY `IDTratta` (`IDTratta`),
  ADD KEY `CodMezzo` (`CodMezzo`);

--
-- Indici per le tabelle `occasionali`
--
ALTER TABLE `occasionali`
  ADD PRIMARY KEY (`CFOccasionale`);

--
-- Indici per le tabelle `passeggeri`
--
ALTER TABLE `passeggeri`
  ADD PRIMARY KEY (`CF`);

--
-- Indici per le tabelle `prenotazioni`
--
ALTER TABLE `prenotazioni`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `IDdisp_Tratta` (`IDdisp_Tratta`),
  ADD KEY `CFPasseggero` (`CFpasseggero`) USING BTREE,
  ADD KEY `data_prenotazione` (`DataPren`);

--
-- Indici per le tabelle `standard`
--
ALTER TABLE `standard`
  ADD PRIMARY KEY (`IDBiglietto`),
  ADD KEY `IDPrenotazione` (`IDPrenotazione`);

--
-- Indici per le tabelle `tratte`
--
ALTER TABLE `tratte`
  ADD PRIMARY KEY (`ID`);

--
-- Indici per le tabelle `viaggi`
--
ALTER TABLE `viaggi`
  ADD PRIMARY KEY (`IDmezzo`);

--
-- AUTO_INCREMENT per le tabelle scaricate
--

--
-- AUTO_INCREMENT per la tabella `abbonati`
--
ALTER TABLE `abbonati`
  MODIFY `IDAbbonato` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT per la tabella `biglietti`
--
ALTER TABLE `biglietti`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT per la tabella `disponib_tratte`
--
ALTER TABLE `disponib_tratte`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT per la tabella `prenotazioni`
--
ALTER TABLE `prenotazioni`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT per la tabella `tratte`
--
ALTER TABLE `tratte`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT per la tabella `viaggi`
--
ALTER TABLE `viaggi`
  MODIFY `IDmezzo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Limiti per le tabelle scaricate
--

--
-- Limiti per la tabella `abbonamenti`
--
ALTER TABLE `abbonamenti`
  ADD CONSTRAINT `abbonamenti_ibfk_1` FOREIGN KEY (`IDBiglietto`) REFERENCES `biglietti` (`ID`),
  ADD CONSTRAINT `abbonamenti_ibfk_2` FOREIGN KEY (`IDAbbonato`) REFERENCES `abbonati` (`IDAbbonato`);

--
-- Limiti per la tabella `abbonati`
--
ALTER TABLE `abbonati`
  ADD CONSTRAINT `abbonati_ibfk_1` FOREIGN KEY (`CFAbbonato`) REFERENCES `passeggeri` (`CF`);

--
-- Limiti per la tabella `dettaglio_viaggi`
--
ALTER TABLE `dettaglio_viaggi`
  ADD CONSTRAINT `dettaglio_viaggi_ibfk_1` FOREIGN KEY (`CodMezzo`) REFERENCES `viaggi` (`IDmezzo`),
  ADD CONSTRAINT `dettaglio_viaggi_ibfk_2` FOREIGN KEY (`IDBiglietto`) REFERENCES `biglietti` (`ID`),
  ADD CONSTRAINT `fk_dettaglioviaggi_biglietto` FOREIGN KEY (`IDBiglietto`) REFERENCES `biglietti` (`ID`);

--
-- Limiti per la tabella `disponib_tratte`
--
ALTER TABLE `disponib_tratte`
  ADD CONSTRAINT `disponib_tratte_ibfk_1` FOREIGN KEY (`IDTratta`) REFERENCES `tratte` (`ID`);

--
-- Limiti per la tabella `fermate`
--
ALTER TABLE `fermate`
  ADD CONSTRAINT `fermate_ibfk_1` FOREIGN KEY (`CodMezzo`) REFERENCES `viaggi` (`IDmezzo`),
  ADD CONSTRAINT `fermate_ibfk_2` FOREIGN KEY (`IDTratta`) REFERENCES `tratte` (`ID`);

--
-- Limiti per la tabella `occasionali`
--
ALTER TABLE `occasionali`
  ADD CONSTRAINT `occasionali_ibfk_1` FOREIGN KEY (`CFOccasionale`) REFERENCES `passeggeri` (`CF`);

--
-- Limiti per la tabella `prenotazioni`
--
ALTER TABLE `prenotazioni`
  ADD CONSTRAINT `CFoccasionale` FOREIGN KEY (`CFpasseggero`) REFERENCES `occasionali` (`CFOccasionale`),
  ADD CONSTRAINT `prenotazioni_ibfk_1` FOREIGN KEY (`IDdisp_Tratta`) REFERENCES `disponib_tratte` (`ID`),
  ADD CONSTRAINT `prenotazioni_ibfk_2` FOREIGN KEY (`CFpasseggero`) REFERENCES `passeggeri` (`CF`);

--
-- Limiti per la tabella `standard`
--
ALTER TABLE `standard`
  ADD CONSTRAINT `standard_ibfk_1` FOREIGN KEY (`IDBiglietto`) REFERENCES `biglietti` (`ID`),
  ADD CONSTRAINT `standard_ibfk_2` FOREIGN KEY (`IDPrenotazione`) REFERENCES `prenotazioni` (`ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
