-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jul 30, 2025 at 12:14 AM
-- Server version: 11.7.2-MariaDB
-- PHP Version: 8.4.7

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: ``
--

-- --------------------------------------------------------

--
-- Table structure for table `artist_equivalencies`
--

CREATE TABLE `artist_equivalencies` (
  `id` int(11) NOT NULL,
  `artist_1` varchar(255) NOT NULL,
  `artist_2` varchar(255) NOT NULL,
  `relationship_type` enum('same_artist','band_member','collaboration','spinoff') DEFAULT 'same_artist',
  `notes` text DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  `created_date` timestamp NULL DEFAULT current_timestamp(),
  `updated_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `artist_equivalencies`
--

INSERT INTO `artist_equivalencies` (`id`, `artist_1`, `artist_2`, `relationship_type`, `notes`, `active`, `created_date`, `updated_date`) VALUES
(1, 'The Beatles', 'John Lennon', 'band_member', 'Beatles member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(2, 'The Beatles', 'Paul McCartney', 'band_member', 'Beatles member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(3, 'The Beatles', 'George Harrison', 'band_member', 'Beatles member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(4, 'The Beatles', 'Ringo Starr', 'band_member', 'Beatles member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(5, 'Paul McCartney', 'Wings', 'band_member', 'Paul McCartney post-Beatles band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(6, 'John Lennon', 'Plastic Ono Band', 'band_member', 'John Lennon band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(7, 'George Harrison', 'Traveling Wilburys', 'band_member', 'Harrison supergroup', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(8, 'Led Zeppelin', 'Robert Plant', 'band_member', 'Led Zeppelin vocalist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(9, 'Led Zeppelin', 'Jimmy Page', 'band_member', 'Led Zeppelin guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(10, 'Led Zeppelin', 'John Paul Jones', 'band_member', 'Led Zeppelin bassist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(11, 'Jimmy Page', 'The Yardbirds', 'band_member', 'Page pre-Led Zeppelin band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(12, 'Pink Floyd', 'David Gilmour', 'band_member', 'Pink Floyd guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(13, 'Pink Floyd', 'Roger Waters', 'band_member', 'Former Pink Floyd bassist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(14, 'Pink Floyd', 'Syd Barrett', 'band_member', 'Original Pink Floyd member', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(15, 'Pink Floyd', 'Nick Mason', 'band_member', 'Pink Floyd drummer - solo work', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(16, 'Pink Floyd', 'Richard Wright', 'band_member', 'Pink Floyd keyboardist - solo work', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(17, 'The Who', 'Roger Daltrey', 'band_member', 'The Who vocalist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(18, 'The Who', 'Pete Townshend', 'band_member', 'The Who guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(19, 'The Who', 'John Entwistle', 'band_member', 'The Who bassist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(20, 'Genesis', 'Phil Collins', 'band_member', 'Genesis drummer/vocalist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(21, 'Genesis', 'Peter Gabriel', 'band_member', 'Original Genesis lead singer', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(22, 'Genesis', 'Mike Rutherford', 'band_member', 'Genesis guitarist', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(23, 'Mike Rutherford', 'Mike + The Mechanics', 'band_member', 'Mike Rutherford side project', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(24, 'Genesis', 'Tony Banks', 'band_member', 'Genesis keyboardist - solo work', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(25, 'Genesis', 'Steve Hackett', 'band_member', 'Former Genesis guitarist', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(26, 'Yes', 'Jon Anderson', 'band_member', 'Yes vocalist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(27, 'Yes', 'Rick Wakeman', 'band_member', 'Yes keyboardist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(28, 'Yes', 'Steve Howe', 'band_member', 'Yes guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(29, 'Yes', 'Chris Squire', 'band_member', 'Yes bassist - solo work', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(30, 'Yes', 'Trevor Rabin', 'band_member', 'Yes guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(31, 'King Crimson', 'Robert Fripp', 'band_member', 'King Crimson guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(32, 'King Crimson', 'Adrian Belew', 'band_member', 'King Crimson guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(33, 'Gary Numan', 'Tubeway Army', 'same_artist', 'Gary Numan was Tubeway Army', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(34, 'Talking Heads', 'David Byrne', 'band_member', 'Talking Heads lead singer - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(35, 'Roxy Music', 'Bryan Ferry', 'band_member', 'Roxy Music vocalist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(36, 'Roxy Music', 'Brian Eno', 'band_member', 'Early Roxy Music member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(37, 'Eagles', 'Don Henley', 'band_member', 'Eagles founding member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(38, 'Eagles', 'Glenn Frey', 'band_member', 'Eagles founding member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(39, 'Eagles', 'Joe Walsh', 'band_member', 'Eagles guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(40, 'Eagles', 'Timothy B. Schmit', 'band_member', 'Eagles bassist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(41, 'Don Henley', 'Glenn Frey', 'band_member', 'Both Eagles founding members', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(42, 'Fleetwood Mac', 'Stevie Nicks', 'band_member', 'Fleetwood Mac vocalist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(43, 'Fleetwood Mac', 'Lindsey Buckingham', 'band_member', 'Fleetwood Mac guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(44, 'Fleetwood Mac', 'Christine McVie', 'band_member', 'Fleetwood Mac vocalist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(45, 'Fleetwood Mac', 'Peter Green', 'band_member', 'Original Fleetwood Mac guitarist', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(46, 'Crosby, Stills & Nash', 'Crosby, Stills, Nash & Young', 'collaboration', 'CSN with Neil Young', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(47, 'Crosby, Stills & Nash', 'David Crosby', 'band_member', 'CSN member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(48, 'Crosby, Stills & Nash', 'Stephen Stills', 'band_member', 'CSN member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(49, 'Crosby, Stills & Nash', 'Graham Nash', 'band_member', 'CSN member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(50, 'Crosby, Stills, Nash & Young', 'Neil Young', 'band_member', 'CSNY member - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(51, 'Neil Young', 'Buffalo Springfield', 'band_member', 'Neil Young early band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(52, 'Stephen Stills', 'Buffalo Springfield', 'band_member', 'Stills early band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(53, 'Black Sabbath', 'Ozzy Osbourne', 'band_member', 'Original Black Sabbath lead singer', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(54, 'Black Sabbath', 'Tony Iommi', 'band_member', 'Black Sabbath guitarist - solo work', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(55, 'Black Sabbath', 'Dio', 'band_member', 'Black Sabbath vocalist after Ozzy', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(56, 'Deep Purple', 'Ian Gillan', 'band_member', 'Deep Purple vocalist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(57, 'Deep Purple', 'Ritchie Blackmore', 'band_member', 'Deep Purple guitarist', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(58, 'Ritchie Blackmore', 'Rainbow', 'band_member', 'Blackmore post-Deep Purple band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(59, 'Deep Purple', 'David Coverdale', 'band_member', 'Deep Purple vocalist', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(60, 'David Coverdale', 'Whitesnake', 'band_member', 'Coverdale post-Deep Purple band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(61, 'The Police', 'Sting', 'band_member', 'The Police lead singer - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(62, 'Sex Pistols', 'Johnny Rotten', 'band_member', 'Sex Pistols vocalist', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(63, 'Johnny Rotten', 'Public Image Ltd', 'band_member', 'Johnny Rotten post-Pistols band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(64, 'Johnny Rotten', 'John Lydon', 'same_artist', 'Real name vs stage name', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(65, 'The Clash', 'Joe Strummer', 'band_member', 'The Clash vocalist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(66, 'The Clash', 'Mick Jones', 'band_member', 'The Clash guitarist', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(67, 'Mick Jones', 'Big Audio Dynamite', 'band_member', 'Mick Jones post-Clash band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(68, 'R.E.M.', 'Michael Stipe', 'band_member', 'R.E.M. vocalist - solo work', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(69, 'R.E.M.', 'Peter Buck', 'band_member', 'R.E.M. guitarist - side projects', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(70, 'Sonic Youth', 'Thurston Moore', 'band_member', 'Sonic Youth guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(71, 'Sonic Youth', 'Kim Deal', 'band_member', 'Sonic Youth bassist - solo work', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(72, 'Cream', 'Eric Clapton', 'band_member', 'Cream guitarist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(73, 'Eric Clapton', 'Derek and the Dominos', 'band_member', 'Clapton band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(74, 'Eric Clapton', 'Blind Faith', 'band_member', 'Clapton supergroup', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(75, 'Cream', 'Jack Bruce', 'band_member', 'Cream bassist - solo career', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(76, 'Peter Green\'s Fleetwood Mac', 'Fleetwood Mac', 'same_artist', 'Early name variation', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(77, 'Traveling Wilburys', 'Bob Dylan', 'band_member', 'Traveling Wilburys member', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(78, 'Traveling Wilburys', 'Tom Petty', 'band_member', 'Traveling Wilburys member', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(79, 'Traveling Wilburys', 'Jeff Lynne', 'band_member', 'Traveling Wilburys member', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(80, 'Traveling Wilburys', 'Roy Orbison', 'band_member', 'Traveling Wilburys member', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(81, 'Blind Faith', 'Steve Winwood', 'band_member', 'Blind Faith keyboardist', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(82, 'Steve Winwood', 'Traffic', 'band_member', 'Winwood main band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(83, 'Steve Winwood', 'Spencer Davis Group', 'band_member', 'Winwood early band', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(84, 'Crosby, Stills & Nash', 'Crosby, Stills and Nash', 'same_artist', 'Alternative naming', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(85, 'Crosby, Stills, Nash & Young', 'Crosby, Stills, Nash and Young', 'same_artist', 'Alternative naming', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(86, 'Emerson, Lake & Palmer', 'Emerson, Lake and Palmer', 'same_artist', 'Alternative naming', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(87, 'Peter, Paul & Mary', 'Peter, Paul and Mary', 'same_artist', 'Alternative naming', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(88, 'Simon & Garfunkel', 'Simon and Garfunkel', 'same_artist', 'Alternative naming', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(89, 'Hall & Oates', 'Daryl Hall & John Oates', 'same_artist', 'Alternative naming', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(90, 'Hall & Oates', 'Hall and Oates', 'same_artist', 'Alternative naming', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(91, 'CCR', 'Creedence Clearwater Revival', 'same_artist', 'Abbreviated name', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(92, 'ELO', 'Electric Light Orchestra', 'same_artist', 'Abbreviated name', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(93, 'ELP', 'Emerson, Lake & Palmer', 'same_artist', 'Abbreviated name', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(94, 'CSN', 'Crosby, Stills & Nash', 'same_artist', 'Abbreviated name', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(95, 'CSNY', 'Crosby, Stills, Nash & Young', 'same_artist', 'Abbreviated name', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(96, 'Tom Petty', 'Tom Petty & The Heartbreakers', 'same_artist', 'Solo vs band name', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(97, 'Tom Petty & The Heartbreakers', 'Tom Petty and the Heartbreakers', 'same_artist', 'Alternative naming', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(98, 'Bob Seger', 'Bob Seger & The Silver Bullet Band', 'same_artist', 'Solo vs band name', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(99, 'Bruce Springsteen', 'Bruce Springsteen & The E Street Band', 'same_artist', 'Solo vs band name', 1, '2025-07-19 11:40:06', '2025-07-19 11:40:06'),
(100, 'John Lennon', 'The Beatles', 'band_member', 'Beatles member - solo career', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(101, 'Paul McCartney', 'The Beatles', 'band_member', 'Beatles member - solo career', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(102, 'George Harrison', 'The Beatles', 'band_member', 'Beatles member - solo career', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(103, 'Ringo Starr', 'The Beatles', 'band_member', 'Beatles member - solo career', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(104, 'Phil Collins', 'Genesis', 'band_member', 'Genesis drummer/vocalist - solo career', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(105, 'Peter Gabriel', 'Genesis', 'band_member', 'Original Genesis lead singer', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(106, 'Sting', 'The Police', 'band_member', 'The Police lead singer - solo career', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(107, 'David Byrne', 'Talking Heads', 'band_member', 'Talking Heads lead singer - solo career', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(108, 'Ozzy Osbourne', 'Black Sabbath', 'band_member', 'Original Black Sabbath lead singer', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(109, 'Robert Plant', 'Led Zeppelin', 'band_member', 'Led Zeppelin vocalist - solo career', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(110, 'Jimmy Page', 'Led Zeppelin', 'band_member', 'Led Zeppelin guitarist - solo career', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(111, 'Tubeway Army', 'Gary Numan', 'same_artist', 'Gary Numan was Tubeway Army', 1, '2025-07-19 11:40:56', '2025-07-19 11:40:56'),
(112, 'Wings', 'The Beatles', 'collaboration', 'Both featured Paul McCartney', 1, '2025-07-19 11:42:17', '2025-07-19 11:42:17'),
(113, 'Wings', 'John Lennon', 'collaboration', 'Beatles connection via McCartney', 1, '2025-07-19 11:42:17', '2025-07-19 11:42:17'),
(114, 'Wings', 'George Harrison', 'collaboration', 'Beatles connection via McCartney', 1, '2025-07-19 11:42:17', '2025-07-19 11:42:17'),
(115, 'Wings', 'Ringo Starr', 'collaboration', 'Beatles connection via McCartney', 1, '2025-07-19 11:42:17', '2025-07-19 11:42:17'),
(116, 'Plastic Ono Band', 'The Beatles', 'collaboration', 'Both featured John Lennon', 1, '2025-07-19 11:42:17', '2025-07-19 11:42:17'),
(117, 'Plastic Ono Band', 'Paul McCartney', 'collaboration', 'Beatles connection via Lennon', 1, '2025-07-19 11:42:17', '2025-07-19 11:42:17'),
(118, 'Plastic Ono Band', 'George Harrison', 'collaboration', 'Beatles connection via Lennon', 1, '2025-07-19 11:42:17', '2025-07-19 11:42:17'),
(119, 'Plastic Ono Band', 'Ringo Starr', 'collaboration', 'Beatles connection via Lennon', 1, '2025-07-19 11:42:17', '2025-07-19 11:42:17'),
(120, 'Traveling Wilburys', 'The Beatles', 'collaboration', 'Both featured George Harrison', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(121, 'Traveling Wilburys', 'John Lennon', 'collaboration', 'Beatles connection via Harrison', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(122, 'Traveling Wilburys', 'Paul McCartney', 'collaboration', 'Beatles connection via Harrison', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(123, 'Traveling Wilburys', 'Ringo Starr', 'collaboration', 'Beatles connection via Harrison', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(124, 'Mike + The Mechanics', 'Genesis', 'collaboration', 'Both featured Mike Rutherford', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(125, 'Mike + The Mechanics', 'Phil Collins', 'collaboration', 'Genesis connection via Rutherford', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(126, 'Mike + The Mechanics', 'Peter Gabriel', 'collaboration', 'Genesis connection via Rutherford', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(127, 'Phil Collins', 'Peter Gabriel', 'collaboration', 'Both were in Genesis', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(128, 'The Yardbirds', 'Led Zeppelin', 'collaboration', 'Both featured Jimmy Page', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(129, 'The Yardbirds', 'Robert Plant', 'collaboration', 'Led Zeppelin connection via Page', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(130, 'The Yardbirds', 'John Paul Jones', 'collaboration', 'Led Zeppelin connection via Page', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(131, 'Don Henley', 'Joe Walsh', 'collaboration', 'Both Eagles members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(132, 'Don Henley', 'Timothy B. Schmit', 'collaboration', 'Both Eagles members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(133, 'Glenn Frey', 'Joe Walsh', 'collaboration', 'Both Eagles members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(134, 'Glenn Frey', 'Timothy B. Schmit', 'collaboration', 'Both Eagles members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(135, 'Joe Walsh', 'Timothy B. Schmit', 'collaboration', 'Both Eagles members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(136, 'Stevie Nicks', 'Lindsey Buckingham', 'collaboration', 'Both Fleetwood Mac members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(137, 'Stevie Nicks', 'Christine McVie', 'collaboration', 'Both Fleetwood Mac members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(138, 'Lindsey Buckingham', 'Christine McVie', 'collaboration', 'Both Fleetwood Mac members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(139, 'David Crosby', 'Stephen Stills', 'collaboration', 'Both CSN members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(140, 'David Crosby', 'Graham Nash', 'collaboration', 'Both CSN members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(141, 'Stephen Stills', 'Graham Nash', 'collaboration', 'Both CSN members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(142, 'Buffalo Springfield', 'Crosby, Stills & Nash', 'collaboration', 'Shared Stephen Stills', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(143, 'Buffalo Springfield', 'Crosby, Stills, Nash & Young', 'collaboration', 'Shared Neil Young & Stephen Stills', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(144, 'Buffalo Springfield', 'David Crosby', 'collaboration', 'CSN connection via Stills', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(145, 'Buffalo Springfield', 'Graham Nash', 'collaboration', 'CSN connection via Stills', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(146, 'Rainbow', 'Black Sabbath', 'collaboration', 'Shared Dio as vocalist', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(147, 'Rainbow', 'Deep Purple', 'collaboration', 'Both featured Ritchie Blackmore', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(148, 'Rainbow', 'Ozzy Osbourne', 'collaboration', 'Black Sabbath connection via Dio', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(149, 'Whitesnake', 'Deep Purple', 'collaboration', 'Both featured David Coverdale', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(150, 'Whitesnake', 'Black Sabbath', 'collaboration', 'Heavy metal connection', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(151, 'Traveling Wilburys', 'Tom Petty & The Heartbreakers', 'collaboration', 'Both featured Tom Petty', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(152, 'Traveling Wilburys', 'Electric Light Orchestra', 'collaboration', 'Both featured Jeff Lynne', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(153, 'Blind Faith', 'Cream', 'collaboration', 'Both featured Eric Clapton', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(154, 'Blind Faith', 'Traffic', 'collaboration', 'Both featured Steve Winwood', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(155, 'Traffic', 'Cream', 'collaboration', 'Blind Faith connection', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(156, 'Derek and the Dominos', 'Cream', 'collaboration', 'Both featured Eric Clapton', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(157, 'Derek and the Dominos', 'Blind Faith', 'collaboration', 'Both featured Eric Clapton', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(158, 'Big Audio Dynamite', 'The Clash', 'collaboration', 'Both featured Mick Jones', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(159, 'Big Audio Dynamite', 'Joe Strummer', 'collaboration', 'The Clash connection via Jones', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(160, 'Public Image Ltd', 'Sex Pistols', 'collaboration', 'Both featured Johnny Rotten', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(161, 'Thurston Moore', 'Kim Deal', 'collaboration', 'Both Sonic Youth members', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(162, 'Spencer Davis Group', 'Traffic', 'collaboration', 'Both featured Steve Winwood', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(163, 'Spencer Davis Group', 'Blind Faith', 'collaboration', 'Winwood connection', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(164, 'Spencer Davis Group', 'Cream', 'collaboration', 'Blind Faith connection via Winwood', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(165, 'Tom Petty', 'Bob Dylan', 'collaboration', 'Both in Traveling Wilburys', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(166, 'Tom Petty', 'George Harrison', 'collaboration', 'Both in Traveling Wilburys', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(167, 'Tom Petty', 'Roy Orbison', 'collaboration', 'Both in Traveling Wilburys', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(168, 'Tom Petty', 'Jeff Lynne', 'collaboration', 'Both in Traveling Wilburys', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(169, 'Tom Petty & The Heartbreakers', 'Bob Dylan', 'collaboration', 'Traveling Wilburys connection', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(170, 'Tom Petty & The Heartbreakers', 'Electric Light Orchestra', 'collaboration', 'Jeff Lynne connection', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(171, 'Electric Light Orchestra', 'The Beatles', 'collaboration', 'Jeff Lynne produced Beatles', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(172, 'Jeff Lynne', 'Paul McCartney', 'collaboration', 'Producer relationship', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(173, 'Jeff Lynne', 'George Harrison', 'collaboration', 'Producer and Traveling Wilburys', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(174, 'Brian Eno', 'David Bowie', 'collaboration', 'Berlin Trilogy producer', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(175, 'Brian Eno', 'Talking Heads', 'collaboration', 'Producer relationship', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(176, 'Brian Eno', 'U2', 'collaboration', 'Producer relationship', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(177, 'Roxy Music', 'David Bowie', 'collaboration', 'Brian Eno connection', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18'),
(178, 'Roxy Music', 'Talking Heads', 'collaboration', 'Brian Eno connection', 1, '2025-07-19 11:42:18', '2025-07-19 11:42:18');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `artist_equivalencies`
--
ALTER TABLE `artist_equivalencies`
  ADD UNIQUE KEY `id` (`id`),
  ADD UNIQUE KEY `unique_pair` (`artist_1`,`artist_2`),
  ADD KEY `artist_1` (`artist_1`),
  ADD KEY `artist_2` (`artist_2`),
  ADD KEY `active` (`active`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `artist_equivalencies`
--
ALTER TABLE `artist_equivalencies`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=179;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
