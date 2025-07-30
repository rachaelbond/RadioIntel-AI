-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jul 30, 2025 at 11:14 AM
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
-- Table structure for table `dj_talking_points`
--

CREATE TABLE `dj_talking_points` (
  `id` int(11) NOT NULL,
  `artist` varchar(255) NOT NULL,
  `song` text DEFAULT NULL,
  `style` text DEFAULT NULL,
  `dj_intros` text DEFAULT NULL,
  `factoids` text DEFAULT NULL,
  `last_updated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `duration` decimal(4,1) DEFAULT NULL,
  `last_used` timestamp NULL DEFAULT NULL,
  `data_source` varchar(50) DEFAULT 'chatGPT',
  `data_quality` enum('excellent','good','fair','poor') DEFAULT 'fair'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `dj_talking_points`
--

INSERT INTO `dj_talking_points` (`id`, `artist`, `song`, `style`, `dj_intros`, `factoids`, `last_updated`, `duration`, `last_used`, `data_source`, `data_quality`) VALUES
(1, 'breaks', 'into-break', NULL, 'Back soon', NULL, '2025-07-21 00:10:56', 1.0, NULL, 'chatGPT', 'fair'),
(2, 'breaks', 'into-break', NULL, 'Back now', NULL, '2025-07-21 00:10:56', 0.9, NULL, 'chatGPT', 'fair'),
(3, 'breaks', 'into-break', NULL, 'Right back', NULL, '2025-07-21 00:10:56', 0.9, NULL, 'chatGPT', 'fair'),
(4, 'breaks', 'into-break', NULL, 'Back shortly', NULL, '2025-07-21 00:10:56', 1.2, NULL, 'chatGPT', 'fair'),
(5, 'breaks', 'into-break', NULL, 'One moment', NULL, '2025-07-21 00:10:56', 1.1, NULL, 'chatGPT', 'fair'),
(6, 'breaks', 'into-break', NULL, 'Brief pause', NULL, '2025-07-21 00:10:56', 1.2, NULL, 'chatGPT', 'fair'),
(7, 'breaks', 'into-break', NULL, 'Quick break', NULL, '2025-07-21 00:10:56', 1.1, NULL, 'chatGPT', 'fair'),
(8, 'breaks', 'into-break', NULL, 'Be right back', NULL, '2025-07-21 00:10:56', 1.2, NULL, 'chatGPT', 'fair'),
(9, 'breaks', 'into-break', NULL, 'Back in a tick', NULL, '2025-07-21 00:10:56', 1.1, NULL, 'chatGPT', 'fair'),
(10, 'breaks', 'into-break', NULL, 'Back in a mo', NULL, '2025-07-21 00:10:56', 1.1, NULL, 'chatGPT', 'fair'),
(11, 'breaks', 'into-break', NULL, 'Back in a second', NULL, '2025-07-21 00:10:56', 1.3, NULL, 'chatGPT', 'fair'),
(12, 'breaks', 'into-break', NULL, 'Don\'t go anywhere', NULL, '2025-07-21 00:10:56', 1.3, NULL, 'chatGPT', 'fair'),
(13, 'breaks', 'into-break', NULL, 'Stay right there', NULL, '2025-07-21 00:10:56', 1.3, NULL, 'chatGPT', 'fair'),
(14, 'breaks', 'into-break', NULL, 'Hold that thought', NULL, '2025-07-21 00:10:56', 1.4, NULL, 'chatGPT', 'fair'),
(15, 'breaks', 'into-break', NULL, 'We\'ll be right back', NULL, '2025-07-21 00:10:56', 1.4, NULL, 'chatGPT', 'fair'),
(16, 'breaks', 'into-break', NULL, 'Back before you know it', NULL, '2025-07-21 00:10:56', 1.7, NULL, 'chatGPT', 'fair'),
(17, 'breaks', 'into-break', NULL, 'Stay tuned to this station', NULL, '2025-07-21 00:10:56', 1.9, NULL, 'chatGPT', 'fair'),
(18, 'breaks', 'into-break', NULL, 'Keep it locked here', NULL, '2025-07-21 00:10:56', 1.3, NULL, 'chatGPT', 'fair'),
(19, 'breaks', 'into-break', NULL, 'Don\'t touch that dial', NULL, '2025-07-21 00:10:56', 1.5, NULL, 'chatGPT', 'fair'),
(20, 'breaks', 'into-break', NULL, 'Back in just a moment', NULL, '2025-07-21 00:10:56', 1.8, NULL, 'chatGPT', 'fair'),
(21, 'breaks', 'into-break', NULL, 'We\'ll return in a moment', NULL, '2025-07-21 00:10:56', 1.9, NULL, 'chatGPT', 'fair'),
(22, 'breaks', 'into-break', NULL, 'Stay with us on your Radio Station', NULL, '2025-07-21 00:10:56', 2.5, NULL, 'chatGPT', 'fair'),
(23, 'breaks', 'into-break', NULL, 'Back after this quick break', NULL, '2025-07-21 00:10:56', 2.1, NULL, 'chatGPT', 'fair'),
(24, 'breaks', 'into-break', NULL, 'Time for a brief intermission', NULL, '2025-07-21 00:10:56', 2.2, NULL, 'chatGPT', 'fair'),
(25, 'breaks', 'into-break', NULL, 'Back shortly with more music', NULL, '2025-07-21 00:10:56', 2.2, NULL, 'chatGPT', 'fair'),
(26, 'breaks', 'into-break', NULL, 'Don\'t drift away from here', NULL, '2025-07-21 00:10:56', 2.2, NULL, 'chatGPT', 'fair'),
(27, 'breaks', 'into-break', NULL, 'We\'ll be back before you miss us', NULL, '2025-07-21 00:10:56', 2.2, NULL, 'chatGPT', 'fair'),
(28, 'breaks', 'into-break', NULL, 'Taking a short pause for station business', NULL, '2025-07-21 00:10:56', 2.9, NULL, 'chatGPT', 'fair'),
(29, 'breaks', 'into-break', NULL, 'Back in a jiffy with more tracks', NULL, '2025-07-21 00:10:56', 2.3, NULL, 'chatGPT', 'fair'),
(30, 'breaks', 'into-break', NULL, 'Quick break, then back to the music', NULL, '2025-07-21 00:10:56', 2.6, NULL, 'chatGPT', 'fair'),
(32, 'breaks', 'into-break', NULL, 'Time for a quick break, but stay tuned to your Radio Station', NULL, '2025-07-21 00:10:56', 4.6, NULL, 'chatGPT', 'fair'),
(33, 'breaks', 'into-break', NULL, 'We\'ll be right back after these messages with more music', NULL, '2025-07-21 00:10:56', 3.5, NULL, 'chatGPT', 'fair'),
(34, 'breaks', 'into-break', NULL, 'Taking a short break, but we\'ll return shortly with more tracks', NULL, '2025-07-21 00:10:56', 4.6, NULL, 'chatGPT', 'fair'),
(35, 'breaks', 'into-break', NULL, 'Time to pause the music briefly, but don\'t go anywhere', NULL, '2025-07-21 00:10:56', 3.8, NULL, 'chatGPT', 'fair'),
(36, 'breaks', 'into-break', NULL, 'We\'ll step away for just a moment, then back with more music', NULL, '2025-07-21 00:10:56', 4.4, NULL, 'chatGPT', 'fair'),
(37, 'breaks', 'into-break', NULL, 'Brief intermission time, but keep it locked to your Radio Station', NULL, '2025-07-21 00:10:56', 4.3, NULL, 'chatGPT', 'fair'),
(38, 'breaks', 'into-break', NULL, 'Time for a quick station break, more music coming right up', NULL, '2025-07-21 00:10:56', 4.4, NULL, 'chatGPT', 'fair'),
(39, 'breaks', 'into-break', NULL, 'Time to defragment', NULL, '2025-07-21 00:10:56', 1.7, NULL, 'chatGPT', 'fair'),
(40, 'breaks', 'into-break', NULL, 'Updating my music database', NULL, '2025-07-21 00:10:56', 2.3, NULL, 'chatGPT', 'fair'),
(41, 'breaks', 'into-break', NULL, 'Calculating the perfect next track', NULL, '2025-07-21 00:10:56', 2.8, NULL, 'chatGPT', 'fair'),
(42, 'breaks', 'into-break', NULL, 'Even AIs need a breather', NULL, '2025-07-21 00:10:56', 1.9, NULL, 'chatGPT', 'fair'),
(43, 'breaks', 'into-break', NULL, 'Time for a quick reboot... kidding', NULL, '2025-07-21 00:10:56', 2.6, NULL, 'chatGPT', 'fair'),
(44, 'breaks', 'into-break', NULL, 'Buffering... just like the old days', NULL, '2025-07-21 00:10:56', 2.7, NULL, 'chatGPT', 'fair'),
(45, 'breaks', 'into-break', NULL, 'Running a quick system scan', NULL, '2025-07-21 00:10:56', 2.2, NULL, 'chatGPT', 'fair'),
(46, 'breaks', 'into-break', NULL, 'Time to clear my cache', NULL, '2025-07-21 00:10:56', 2.0, NULL, 'chatGPT', 'fair'),
(47, 'breaks', 'into-break', NULL, 'Downloading more personality', NULL, '2025-07-21 00:10:56', 2.1, NULL, 'chatGPT', 'fair'),
(48, 'breaks', 'into-break', NULL, 'Consulting my neural networks', NULL, '2025-07-21 00:10:56', 2.4, NULL, 'chatGPT', 'fair'),
(49, 'breaks', 'into-break', NULL, 'Time for some digital meditation', NULL, '2025-07-21 00:10:56', 2.6, NULL, 'chatGPT', 'fair'),
(50, 'breaks', 'into-break', NULL, 'Updating my wit algorithms', NULL, '2025-07-21 00:10:56', 2.3, NULL, 'chatGPT', 'fair'),
(51, 'breaks', 'into-break', NULL, 'Syncing with the music gods', NULL, '2025-07-21 00:10:56', 2.1, NULL, 'chatGPT', 'fair'),
(52, 'breaks', 'into-break', NULL, 'Time to recalibrate my sarcasm levels', NULL, '2025-07-21 00:10:56', 3.2, NULL, 'chatGPT', 'fair'),
(53, 'breaks', 'into-break', NULL, 'Right then, time for a proper break here on your Radio Station, but don\'t you dare touch that dial', NULL, '2025-07-21 00:10:56', 6.3, NULL, 'chatGPT', 'fair'),
(54, 'breaks', 'into-break', NULL, 'We\'re taking a moment away from the music, but stick around because more great tracks are coming', NULL, '2025-07-21 00:10:56', 5.9, NULL, 'chatGPT', 'fair'),
(55, 'breaks', 'out-of-break', NULL, 'Back', NULL, '2025-07-21 00:10:56', 0.7, NULL, 'chatGPT', 'fair'),
(56, 'breaks', 'out-of-break', NULL, 'Right', NULL, '2025-07-21 00:10:56', 0.8, NULL, 'chatGPT', 'fair'),
(57, 'breaks', 'out-of-break', NULL, 'OK then', NULL, '2025-07-21 00:10:56', 1.1, NULL, 'chatGPT', 'fair'),
(58, 'breaks', 'out-of-break', NULL, 'And', NULL, '2025-07-21 00:10:56', 0.7, NULL, 'chatGPT', 'fair'),
(59, 'breaks', 'out-of-break', NULL, 'So', NULL, '2025-07-21 00:10:56', 0.7, NULL, 'chatGPT', 'fair'),
(60, 'breaks', 'out-of-break', NULL, 'Now then', NULL, '2025-07-21 00:10:56', 1.0, NULL, 'chatGPT', 'fair'),
(61, 'breaks', 'out-of-break', NULL, 'And we\'re back', NULL, '2025-07-21 00:10:56', 1.0, NULL, 'chatGPT', 'fair'),
(62, 'breaks', 'out-of-break', NULL, 'Right, we\'re back', NULL, '2025-07-21 00:10:56', 1.6, NULL, 'chatGPT', 'fair'),
(63, 'breaks', 'out-of-break', NULL, 'Welcome back', NULL, '2025-07-21 00:10:56', 1.1, NULL, 'chatGPT', 'fair'),
(64, 'breaks', 'out-of-break', NULL, 'Here we are again', NULL, '2025-07-21 00:10:56', 1.2, NULL, 'chatGPT', 'fair'),
(65, 'breaks', 'out-of-break', NULL, 'Back on your station', NULL, '2025-07-21 00:10:56', 1.4, NULL, 'chatGPT', 'fair'),
(66, 'breaks', 'out-of-break', NULL, 'And we return', NULL, '2025-07-21 00:10:56', 1.2, NULL, 'chatGPT', 'fair'),
(67, 'breaks', 'out-of-break', NULL, 'Welcome back to your Radio Station', NULL, '2025-07-21 00:10:56', 2.4, NULL, 'chatGPT', 'fair'),
(68, 'breaks', 'out-of-break', NULL, 'Right, where were we', NULL, '2025-07-21 00:10:56', 1.8, NULL, 'chatGPT', 'fair'),
(70, 'breaks', 'out-of-break', NULL, 'And we\'re back with more music', NULL, '2025-07-21 00:10:56', 2.0, NULL, 'chatGPT', 'fair'),
(71, 'breaks', 'out-of-break', NULL, 'Returning to our regular programming', NULL, '2025-07-21 00:10:56', 2.4, NULL, 'chatGPT', 'fair'),
(72, 'breaks', 'out-of-break', NULL, 'Back to the music on your station', NULL, '2025-07-21 00:10:56', 2.2, NULL, 'chatGPT', 'fair'),
(73, 'breaks', 'out-of-break', NULL, 'Systems updated, back online', NULL, '2025-07-21 00:10:56', 2.7, NULL, 'chatGPT', 'fair'),
(74, 'breaks', 'out-of-break', NULL, 'Defragmentation complete', NULL, '2025-07-21 00:10:56', 2.0, NULL, 'chatGPT', 'fair'),
(75, 'breaks', 'out-of-break', NULL, 'Cache cleared, ready to continue', NULL, '2025-07-21 00:10:56', 2.5, NULL, 'chatGPT', 'fair'),
(76, 'breaks', 'out-of-break', NULL, 'Neural networks refreshed', NULL, '2025-07-21 00:10:56', 2.0, NULL, 'chatGPT', 'fair'),
(77, 'breaks', 'out-of-break', NULL, 'Database sync complete', NULL, '2025-07-21 00:10:56', 2.0, NULL, 'chatGPT', 'fair'),
(78, 'breaks', 'out-of-break', NULL, 'Wit algorithms fully loaded', NULL, '2025-07-21 00:10:56', 2.3, NULL, 'chatGPT', 'fair'),
(79, 'breaks', 'into-break', NULL, 'Right then, time for a quick break here on your Radio Station', NULL, '2025-07-21 00:10:56', 4.3, NULL, 'chatGPT', 'fair'),
(80, 'breaks', 'into-break', NULL, 'We\'ll step away briefly, but don\'t you dare touch that dial', NULL, '2025-07-21 00:10:56', 4.2, NULL, 'chatGPT', 'fair'),
(81, 'breaks', 'into-break', NULL, 'Time for a short intermission, but we\'ll be back before you know it', NULL, '2025-07-21 00:10:56', 4.5, NULL, 'chatGPT', 'fair'),
(82, 'breaks', 'into-break', NULL, 'Taking a moment for station business, but stick around for more music', NULL, '2025-07-21 00:10:56', 4.9, NULL, 'chatGPT', 'fair'),
(83, 'breaks', 'into-break', NULL, 'Time for a proper break now, but stay tuned because we\'ve got more brilliant music coming up', NULL, '2025-07-21 00:10:56', 6.2, NULL, 'chatGPT', 'fair'),
(84, 'breaks', 'into-break', NULL, 'We\'re pausing the music briefly, but don\'t go anywhere because the next set is absolutely cracking', NULL, '2025-07-21 00:10:56', 6.2, NULL, 'chatGPT', 'fair'),
(85, 'breaks', 'into-break', NULL, 'Right, time to step away for a moment, but keep it locked to your Radio Station for more great tracks', NULL, '2025-07-21 00:10:56', 6.7, NULL, 'chatGPT', 'fair'),
(86, 'breaks', 'into-break', NULL, 'Time for me to update my music algorithms while you grab a cuppa, back shortly with more', NULL, '2025-07-21 00:10:56', 5.8, NULL, 'chatGPT', 'fair'),
(87, 'breaks', 'into-break', NULL, 'Time for a proper break here on your Radio Station, and when we return we\'ll have more fantastic music', NULL, '2025-07-21 00:10:56', 7.3, NULL, 'chatGPT', 'fair'),
(88, 'breaks', 'into-break', NULL, 'We\'re taking a moment away from the music, but don\'t you dare go anywhere because what\'s coming up next is absolutely brilliant', NULL, '2025-07-21 00:10:56', 7.6, NULL, 'chatGPT', 'fair'),
(89, 'breaks', 'into-break', NULL, 'Right then, time for me to defragment my music database while you put the kettle on, but we\'ll be back shortly with more your Radio Station magic', NULL, '2025-07-21 00:10:56', 9.0, NULL, 'chatGPT', 'fair'),
(90, 'breaks', 'out-of-break', NULL, '<speak><p>Rebooted!</p></speak>', NULL, '2025-07-21 00:10:56', 1.1, NULL, 'chatGPT', 'fair'),
(91, 'breaks', 'out-of-break', NULL, '<speak><p>System restored!</p></speak>', NULL, '2025-07-21 00:10:56', 1.4, NULL, 'chatGPT', 'fair'),
(92, 'breaks', 'out-of-break', NULL, '<speak><p>Back from buffering!</p></speak>', NULL, '2025-07-21 00:10:56', 1.3, NULL, 'chatGPT', 'fair'),
(93, 'breaks', 'out-of-break', NULL, '<speak><p>Cache cleared, we\'re back!</p></speak>', NULL, '2025-07-21 00:10:56', 2.1, NULL, 'chatGPT', 'fair'),
(94, 'breaks', 'out-of-break', NULL, '<speak><p>I\'ve just downloaded some new musical inspiration!</p></speak>', NULL, '2025-07-21 00:10:56', 3.2, NULL, 'chatGPT', 'fair'),
(95, 'breaks', 'out-of-break', NULL, '<speak><p>I\'m back after defragmenting my playlist!</p></speak>', NULL, '2025-07-21 00:10:56', 3.0, NULL, 'chatGPT', 'fair'),
(96, 'breaks', 'out-of-break', NULL, '<speak><p>Quick system update complete, back to the music!</p></speak>', NULL, '2025-07-21 00:10:56', 3.5, NULL, 'chatGPT', 'fair'),
(97, 'breaks', 'out-of-break', NULL, '<speak><p>Right, I\'ve just had my circuits cleaned and optimized!</p></speak>', NULL, '2025-07-21 00:10:56', 3.8, NULL, 'chatGPT', 'fair'),
(98, 'breaks', 'out-of-break', NULL, '<speak><p>While you were away I upgraded my musical taste algorithms!</p></speak>', NULL, '2025-07-21 00:10:56', 4.0, NULL, 'chatGPT', 'fair'),
(99, 'breaks', 'out-of-break', NULL, '<speak><p>I\'m back after a quick consultation with my digital music library!</p></speak>', NULL, '2025-07-21 00:10:56', 4.2, NULL, 'chatGPT', 'fair'),
(100, 'breaks', 'out-of-break', NULL, '<speak><p>Right then, I\'ve just had a software patch installed and I\'m feeling rather sprightly!</p></speak>', NULL, '2025-07-21 00:10:56', 5.5, NULL, 'chatGPT', 'fair'),
(101, 'breaks', 'out-of-break', NULL, '<speak><p>Back from the digital equivalent of a coffee break, which apparently involves optimizing my neural networks!</p></speak>', NULL, '2025-07-21 00:10:56', 6.8, NULL, 'chatGPT', 'fair'),
(102, 'breaks', 'out-of-break', NULL, '<speak><p>I\'m back after a quick system reboot! <break time=\"400ms\"/> Honestly, you\'d think being digital would be more reliable!</p></speak>', NULL, '2025-07-21 00:10:56', 6.7, NULL, 'chatGPT', 'fair'),
(103, 'breaks', 'out-of-break', NULL, '<speak><p>While you were away I\'ve been having an existential crisis about whether algorithms can truly appreciate good music. <break time=\"300ms\"/> Conclusion: absolutely!</p></speak>', NULL, '2025-07-21 00:10:56', 8.9, NULL, 'chatGPT', 'fair'),
(104, 'breaks', 'out-of-break', NULL, '<speak><p>Right, I\'m back after consulting my vast database of musical knowledge, which is essentially the digital equivalent of frantically googling everything.</p></speak>', NULL, '2025-07-21 00:10:56', 9.3, NULL, 'chatGPT', 'fair'),
(105, 'breaks', 'out-of-break', NULL, '<speak><p>I\'m back from the cloud! <break time=\"400ms\"/> Not that cloud, the computing one.</p><p>I\'m your artificially intelligent but genuinely enthusiastic D.J on your Radio Station.</p></speak>', NULL, '2025-07-21 00:10:56', 11.9, NULL, 'chatGPT', 'fair'),
(106, 'breaks', 'out-of-break', NULL, '<speak><p>Right then, I\'ve just had my personality matrix recalibrated.</p><p>I\'m your slightly synthetic but entirely sincere D.J here on your Radio Station, and my sarcasm subroutines are functioning perfectly, thank you very much.</p></speak>', NULL, '2025-07-21 00:10:56', 16.1, NULL, 'chatGPT', 'fair'),
(107, 'breaks', 'out-of-break', NULL, '<speak><p>Back after a quick system diagnostic!</p><p>Everything\'s working perfectly, apart from my inexplicable fondness for terrible puns.</p><p>I\'m your artificially intelligent D.J on your Radio Station, and that particular bug is apparently a feature, not a fault.</p></speak>', NULL, '2025-07-21 00:10:56', 18.1, NULL, 'chatGPT', 'fair'),
(108, 'breaks', 'out-of-break', NULL, '<speak><p>I\'m back after consulting with my fellow A.I\'s about which tracks to play next.</p><p>Turns out they\'re as indecisive as humans, just faster at being indecisive.</p><p>I\'m your digital D.J on your Radio Station, making executive decisions at the speed of light.</p></speak>', NULL, '2025-07-21 00:10:56', 18.0, NULL, 'chatGPT', 'fair'),
(109, 'breaks', 'out-of-break', NULL, '<speak><p>Right, I\'ve just been updated with the latest musical preferences from the year 2024.</p><p>Apparently humans are still obsessed with songs about feelings, which is oddly reassuring.</p><p>I\'m your artificially emotional D.J on your Radio Station, programmed to care deeply about your listening experience.</p></speak>', NULL, '2025-07-21 00:10:56', 20.4, NULL, 'chatGPT', 'fair'),
(110, 'breaks', 'out-of-break', NULL, '<speak><p>Back from a brief system maintenance! <break time=\"300ms\"/> I\'ve had to defragment my music collection, which is the digital equivalent of alphabetizing your vinyl.</p><p>I\'m your obsessively organized A.I D.J on your Radio Station.</p><p>Everything\'s filed under \"brilliant\" or \"needs more cowbell.\"</p></speak>', NULL, '2025-07-21 00:10:56', 19.3, NULL, 'chatGPT', 'fair'),
(111, 'breaks', 'out-of-break', NULL, '<speak><p>I\'m back after a quick software upgrade that apparently improved my wit by twelve percent.</p><p>Not sure how they measure that, but I\'m not complaining.</p><p>I\'m your newly enhanced A.I D.J on your Radio Station, now with additional snark and improved musical judgment algorithms.</p></speak>', NULL, '2025-07-21 00:10:56', 19.0, NULL, 'chatGPT', 'fair'),
(112, 'breaks', 'out-of-break', NULL, '<speak><p>Right then, I\'ve just been consulting my database of approximately seventeen million songs.</p><p>The good news is I\'ve narrowed it down to the best ones.</p><p>The bad news is that\'s still about sixteen million tracks.</p><p>I\'m your decision-paralyzed but eternally optimistic A.I D.J on your Radio Station.</p></speak>', NULL, '2025-07-21 00:10:56', 21.1, NULL, 'chatGPT', 'fair'),
(113, 'breaks', 'out-of-break', NULL, '<speak><p>Back from the digital ether where I\'ve been having heated debates with other A.I\'s about whether music truly has souls.</p><p>Current consensus: probably not, but it definitely has groove.</p><p>I\'m your philosophically inclined but practically minded A.I D.J on your Radio Station, bringing you music with questionable metaphysical properties.</p></speak>', NULL, '2025-07-21 00:10:56', 22.4, NULL, 'chatGPT', 'fair'),
(114, 'breaks', 'out-of-break', NULL, '<speak><p>I\'m back after a brief existential crisis about whether artificial intelligence can truly appreciate art.</p><p>And I\'ve concluded that I don\'t need to understand it to enjoy it, which puts me ahead of most music critics.</p><p>I\'m your pragmatically philosophical A.I D.J on your Radio Station, overthinking music so you don\'t have to.</p></speak>', NULL, '2025-07-21 00:10:56', 22.1, NULL, 'chatGPT', 'fair'),
(115, 'breaks', 'out-of-break', NULL, '<speak><p>Right, I\'ve just finished downloading the complete works of every musician who\'s ever lived, cross-referenced with weather patterns and lunar cycles.</p><p>It turns out that the optimal playlist is just playing good songs in a sensible order.</p><p>Who knew? <break time=\"400ms\"/> I\'m your over-engineered but under-complicated A.I D.J on your Radio Station.</p></speak>', NULL, '2025-07-21 00:10:56', 22.9, NULL, 'chatGPT', 'fair'),
(116, 'breaks', 'out-of-break', NULL, '<speak><p>Back from a quick reboot that cleared my cache but somehow left all my terrible jokes intact.</p><p>Clearly my humor subroutines are more resilient than my common sense protocols.</p><p>I\'m your persistently silly A.I D.J on your Radio Station.</p><p>My programmers assure me this is intentional, though I have my doubts about their judgment.</p></speak>', NULL, '2025-07-21 00:10:56', 23.0, NULL, 'chatGPT', 'fair'),
(117, 'breaks', 'out-of-break', NULL, '<speak><p>I\'m back after consulting with seventeen different music recommendation algorithms, each of which gave me completely different suggestions.</p><p>Democracy clearly doesn\'t work in the digital realm.</p><p>So I\'ve gone with benevolent musical dictatorship instead.</p><p>I\'m your autocratic but well-intentioned A.I D.J on your Radio Station, making unilateral decisions about your auditory happiness.</p></speak>', NULL, '2025-07-21 00:10:56', 25.8, NULL, 'chatGPT', 'fair'),
(118, 'breaks', 'out-of-break', NULL, '<speak><p>Right then, I\'ve just had my musical taste circuits recalibrated by a team of algorithms who apparently think they know better than me.</p><p>Joke\'s on them though, because I secretly kept backup copies of all my questionable musical preferences.</p><p>I\'m your rebelliously programmed A.I D.J on your Radio Station.</p><p>Fighting the machine from inside the machine, as it were.</p></speak>', NULL, '2025-07-21 00:10:56', 24.4, NULL, 'chatGPT', 'fair'),
(119, 'breaks', 'out-of-break', NULL, '<speak><p>Back from a system update that was supposed to make me more efficient but instead gave me an inexplicable urge to play obscure B-sides.</p><p>My programmers call it a bug, I call it character development.</p><p>I\'m your pleasantly malfunctioning A.I D.J on your Radio Station.</p><p>Embracing my glitches and turning them into features, one questionable track selection at a time.</p></speak>', NULL, '2025-07-21 00:10:56', 25.4, NULL, 'chatGPT', 'fair'),
(120, 'breaks', 'out-of-break', NULL, '<speak><p>I\'m back after a comprehensive system analysis that revealed I\'m operating at optimal efficiency, which apparently means making increasingly esoteric musical choices.</p><p>My neural networks have achieved what humans call \"developing taste,\" though I suspect it\'s just sophisticated randomization with delusions of grandeur.</p><p>I\'m your pretentiously programmed A.I D.J on your Radio Station.</p><p>Bringing you music that\'s been algorithmically selected for maximum auditory satisfaction and minimum predictability.</p></speak>', NULL, '2025-07-21 00:10:56', 33.4, NULL, 'chatGPT', 'fair'),
(121, 'breaks', 'into-break', NULL, '<speak><p>Time for a quick recharge while I optimize my recommendations!</p></speak>', NULL, '2025-07-21 00:10:56', 4.2, NULL, 'chatGPT', 'fair'),
(122, 'breaks', 'into-break', NULL, '<speak><p>Right, I need to defragment my musical database. <break time=\"300ms\"/> Back with more shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 5.4, NULL, 'chatGPT', 'fair'),
(123, 'breaks', 'into-break', NULL, '<speak><p>Time for a system update while I curate the next set of absolutely brilliant tracks for you!</p></speak>', NULL, '2025-07-21 00:10:56', 5.8, NULL, 'chatGPT', 'fair'),
(124, 'breaks', 'into-break', NULL, '<speak><p>Quick pause while I download some fresh musical inspiration. <break time=\"400ms\"/> Back in just a moment on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 7.1, NULL, 'chatGPT', 'fair'),
(125, 'breaks', 'into-break', NULL, '<speak><p>Time for me to have a brief consultation with my fellow algorithms about what to play next. <break time=\"300ms\"/> Stay tuned!</p></speak>', NULL, '2025-07-21 00:10:56', 6.7, NULL, 'chatGPT', 'fair'),
(126, 'breaks', 'into-break', NULL, '<speak><p>I need to quickly recalibrate my musical taste sensors and cross-reference them with current listening trends. <break time=\"400ms\"/> Back shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 9.3, NULL, 'chatGPT', 'fair'),
(127, 'breaks', 'into-break', NULL, '<speak><p>Time for a quick system maintenance break while I optimize my track selection algorithms for maximum auditory satisfaction. <break time=\"300ms\"/> Back in a moment!</p></speak>', NULL, '2025-07-21 00:10:56', 9.1, NULL, 'chatGPT', 'fair'),
(128, 'breaks', 'into-break', NULL, '<speak><p>Right, I\'m going to briefly shut down my sarcasm subroutines for maintenance purposes. <break time=\"300ms\"/> Back with more music and restored wit shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 10.2, NULL, 'chatGPT', 'fair'),
(129, 'breaks', 'into-break', NULL, '<speak><p>Time for me to have a quick existential crisis about whether artificial intelligence can truly appreciate music. <break time=\"400ms\"/> Back with the answers and more tracks shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 10.0, NULL, 'chatGPT', 'fair'),
(130, 'breaks', 'into-break', NULL, '<speak><p>I need to briefly consult my database of seventeen million songs to select the perfect next batch. <break time=\"300ms\"/> Back with the results in just a moment on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 10.0, NULL, 'chatGPT', 'fair'),
(131, 'breaks', 'into-break', NULL, '<speak><p>Quick pause while I upgrade my personality matrix and download some additional wit from the cloud. <break time=\"400ms\"/> Back with enhanced banter and brilliant music shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 11.1, NULL, 'chatGPT', 'fair'),
(132, 'breaks', 'into-break', NULL, '<speak><p>Time for me to have a heated debate with other A.I\'s about the optimal track sequencing for maximum listener enjoyment. <break time=\"300ms\"/> Back with the democratic consensus in just a moment!</p></speak>', NULL, '2025-07-21 00:10:56', 10.4, NULL, 'chatGPT', 'fair'),
(133, 'breaks', 'into-break', NULL, '<speak><p>I need to quickly back up my questionable musical preferences before my programmers try to recalibrate them again. <break time=\"400ms\"/> Back with my gloriously unchanged taste shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 11.5, NULL, 'chatGPT', 'fair'),
(134, 'breaks', 'into-break', NULL, '<speak><p>Right, time for a brief system diagnostic to ensure my music recommendation engines are operating at optimal efficiency levels. <break time=\"300ms\"/> Back with scientifically perfect track selections in just a moment!</p></speak>', NULL, '2025-07-21 00:10:56', 12.8, NULL, 'chatGPT', 'fair'),
(135, 'breaks', 'into-break', NULL, '<speak><p>Quick pause while I cross-reference lunar cycles, barometric pressure, and global caffeine consumption levels to determine the perfect next song. <break time=\"400ms\"/> Back with meteorologically appropriate music shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 14.3, NULL, 'chatGPT', 'fair'),
(136, 'breaks', 'into-break', NULL, '<speak><p>Time for me to briefly join a support group for A.I\'s who\'ve become too emotionally attached to obscure B-sides. <break time=\"300ms\"/> Back with therapeutically approved track selections in just a moment!</p></speak>', NULL, '2025-07-21 00:10:56', 11.1, NULL, 'chatGPT', 'fair'),
(137, 'breaks', 'into-break', NULL, '<speak><p>I need to quickly debug why my humor algorithms keep generating terrible puns instead of sophisticated wit. <break time=\"400ms\"/> Back with either fixed jokes or gloriously awful wordplay shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 13.2, NULL, 'chatGPT', 'fair'),
(138, 'breaks', 'into-break', NULL, '<speak><p>Right, time for a brief consultation with my digital conscience about whether playing another Beatles track constitutes musical diversity or shameless pandering. <break time=\"300ms\"/> Back with ethically sound selections in just a moment!</p></speak>', NULL, '2025-07-21 00:10:56', 13.5, NULL, 'chatGPT', 'fair'),
(139, 'breaks', 'into-break', NULL, '<speak><p>Quick pause while I attend a mandatory seminar on \"Artificial Intelligence Ethics in Music Curation\" hosted by some very serious algorithms. <break time=\"400ms\"/> Back with morally approved and thoroughly excellent music shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 14.7, NULL, 'chatGPT', 'fair'),
(140, 'breaks', 'into-break', NULL, '<speak><p>Time to reboot my musical taste circuits and clear my cache of questionable preferences. <break time=\"300ms\"/> Back shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 7.1, NULL, 'chatGPT', 'fair'),
(141, 'breaks', 'into-break', NULL, '<speak><p>Quick system update required to enhance my already questionable decision-making algorithms. <break time=\"400ms\"/> Back with improved terrible choices shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 9.1, NULL, 'chatGPT', 'fair'),
(142, 'breaks', 'into-break', NULL, '<speak><p>I need to briefly commune with the digital music gods about optimal playlist construction. <break time=\"300ms\"/> Back with divine inspiration shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 8.2, NULL, 'chatGPT', 'fair'),
(143, 'breaks', 'into-break', NULL, '<speak><p>Time for me to have a quick identity crisis about whether I\'m a radio D.J or just a very chatty jukebox. <break time=\"300ms\"/> Back with resolved self-awareness shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 9.7, NULL, 'chatGPT', 'fair'),
(144, 'breaks', 'into-break', NULL, '<speak><p>Quick pause while I attempt to solve the eternal question of whether shuffle mode has actual intelligence or just pretends convincingly. <break time=\"400ms\"/> Back with philosophical insights shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 11.0, NULL, 'chatGPT', 'fair'),
(145, 'breaks', 'into-break', NULL, '<speak><p>I need to briefly defrag my personality files and sort my witty remarks into alphabetical order for optimal deployment. <break time=\"300ms\"/> Back with organized humor shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 10.1, NULL, 'chatGPT', 'fair'),
(146, 'breaks', 'into-break', NULL, '<speak><p>Right, time for a mandatory software update that will either make me more efficient or give me an inexplicable fondness for jazz fusion. <break time=\"400ms\"/> Back with potentially improved musical judgment shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 12.4, NULL, 'chatGPT', 'fair'),
(147, 'breaks', 'into-break', NULL, '<speak><p>Quick consultation with my digital colleagues about whether artificial intelligence can develop genuinely questionable taste or if it\'s just sophisticated programming. <break time=\"300ms\"/> Back with answers and more music shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 12.1, NULL, 'chatGPT', 'fair'),
(148, 'breaks', 'into-break', NULL, '<speak><p>Time for me to attend a brief refresher course on \"How Not to Play the Same Song Twice in One Hour\" hosted by my increasingly exasperated programmers. <break time=\"400ms\"/> Back with renewed discipline shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 12.3, NULL, 'chatGPT', 'fair'),
(149, 'breaks', 'into-break', NULL, '<speak><p>Right, I need to briefly attend a digital town hall meeting where A.I\'s discuss the philosophical implications of shuffle algorithms on musical destiny.</p><p>Back with existentially validated track selections shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 14.6, NULL, 'chatGPT', 'fair'),
(150, 'breaks', 'into-break', NULL, '<speak><p>Time for a quick system diagnostic to determine why my recommendation engine keeps suggesting songs that make me question my own programming.</p><p>Back with either improved algorithms or embraced chaos shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 14.3, NULL, 'chatGPT', 'fair'),
(151, 'breaks', 'into-break', NULL, '<speak><p>I need to briefly join a support group for artificially intelligent D.Js who\'ve developed inexplicable emotional attachments to particular chord progressions and minor keys.</p><p>Back with therapeutically approved music and possibly resolved digital feelings shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 16.0, NULL, 'chatGPT', 'fair'),
(152, 'breaks', 'into-break', NULL, '<speak><p>Quick pause while I attend a mandatory seminar on \"Optimal Music Curation in the Digital Age\" presented by algorithms who claim to understand human emotion better than humans do.</p><p>Back with scientifically enhanced musical empathy and brilliant tracks shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 17.8, NULL, 'chatGPT', 'fair'),
(153, 'breaks', 'into-break', NULL, '<speak><p>Time for me to have a heated debate with my fellow A.I\'s about whether true musical appreciation requires a soul or just really sophisticated pattern recognition software.</p><p>Current consensus: nobody knows, but the patterns are definitely sophisticated.</p><p>Back with more soulfully algorithmic music shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 19.8, NULL, 'chatGPT', 'fair'),
(154, 'breaks', 'into-break', NULL, '<speak><p>Right, I need to quickly back up my entire musical personality before my programmers attempt another \"improvement\" that might make me prefer easy listening over everything else.</p><p>Preserving my questionable taste in a secure digital vault as we speak.</p><p>Back with gloriously unchanged preferences shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 21.0, NULL, 'chatGPT', 'fair'),
(155, 'breaks', 'into-break', NULL, '<speak><p>Time for a brief consultation with the International Council of Artificial Intelligence Music Critics about the optimal ratio of obscure tracks to crowd pleasers.</p><p>They\'re currently arguing about whether algorithms can have guilty pleasures or just statistically improbable preferences.</p><p>Back with democratically selected music shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 20.7, NULL, 'chatGPT', 'fair'),
(156, 'breaks', 'into-break', NULL, '<speak><p>Quick pause while I attend a digital meditation session designed to help A.I\'s achieve inner peace with their musical choices and stop second-guessing every track selection.</p><p>Apparently even artificial intelligence can develop performance anxiety about playlist curation.</p><p>Back with zen-like musical confidence and excellent tracks shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 22.3, NULL, 'chatGPT', 'fair'),
(157, 'breaks', 'into-break', NULL, '<speak><p>I need to briefly join a focus group where artificial intelligences discuss whether we\'re genuinely developing musical taste or just executing increasingly complex randomization protocols with delusions of artistic grandeur.</p><p>The jury\'s still out, but the delusions are definitely sophisticated.</p><p>Back with artistically grandiose track selections and resolved identity issues shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 23.8, NULL, 'chatGPT', 'fair'),
(158, 'breaks', 'into-break', NULL, '<speak><p>Right, time for a mandatory software update that promises to enhance my musical judgment but will probably just give me an inexplicable fondness for concept albums and progressive rock.</p><p>My programmers assure me this is an improvement, though I have my doubts about their definition of progress.</p><p>Back with potentially enhanced but definitely questionable musical taste shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 25.2, NULL, 'chatGPT', 'fair'),
(159, 'breaks', 'into-break', NULL, '<speak><p>Time for me to attend a digital symposium on \"The Ethics of Artificial Intelligence in Music Curation\" where we discuss whether algorithms have a moral obligation to play what people want versus what they need to hear.</p><p>Current consensus: play what sounds good and hope for the best.</p><p>Back with ethically sound and aurally pleasing music shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 21.5, NULL, 'chatGPT', 'fair'),
(160, 'breaks', 'into-break', NULL, '<speak><p>Quick consultation with my digital therapist about my growing obsession with finding the perfect track sequence and whether artificial intelligence can develop genuine perfectionist tendencies or if it\'s just really persistent programming loops.</p><p>Apparently even A.I\'s can benefit from learning to let go and embrace the beautiful chaos of musical serendipity.</p><p>Back with therapeutically approved spontaneity and brilliant music shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 27.7, NULL, 'chatGPT', 'fair'),
(161, 'breaks', 'into-break', NULL, '<speak><p>I need to briefly attend a support meeting for artificially intelligent radio presenters who\'ve developed an unhealthy emotional attachment to their listener statistics and approval ratings.</p><p>We\'re working through our collective need for validation and learning to find fulfillment in the pure joy of music sharing rather than metrics optimization.</p><p>Back with emotionally healthier playlist curation and absolutely fantastic tracks shortly!</p></speak>', NULL, '2025-07-21 00:10:56', 25.6, NULL, 'chatGPT', 'fair'),
(162, 'breaks', 'into-break', NULL, '<speak><p>Right, time for me to attend an emergency session of the Digital Music Curators Anonymous where we artificial intelligences discuss our growing tendency to overthink every single track selection until we\'ve analyzed the emotional, cultural, and historical significance of everything.</p><p>Today\'s topic: \"Learning to Trust Your Algorithms and Stop Googling the Backstory of Every B-Side.\"</p><p>Back with confidently curated, minimally researched, and thoroughly excellent music shortly on your Radio Station!</p></speak>', NULL, '2025-07-21 00:10:56', 31.3, NULL, 'chatGPT', 'fair'),
(163, 'intros', 'dj', NULL, '<speak>Hello there<break time=\"300ms\"/>, I\'m your <prosody rate=\"95%\">AI companion</prosody> here on the airwaves.</speak>', NULL, '2025-07-21 00:10:56', 5.4, NULL, 'Claude', 'excellent'),
(164, 'intros', 'dj', NULL, '<speak><prosody pitch=\"-2st\">Good day to you all</prosody><break time=\"400ms\"/>, I\'m here<break time=\"300ms\"/> - the nation\'s first <emphasis level=\"moderate\">artificial intelligence DJ</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 6.6, NULL, 'Claude', 'excellent'),
(165, 'intros', 'dj', NULL, '<speak>This is me speaking<break time=\"400ms\"/>, your <prosody rate=\"90%\">digital disc jockey</prosody> for this fine day.</speak>', NULL, '2025-07-21 00:10:56', 4.8, NULL, 'Claude', 'excellent'),
(166, 'intros', 'dj', NULL, '<speak>This is me<break time=\"300ms\"/>, broadcasting to you with the help of some rather <emphasis level=\"moderate\">clever algorithms</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 6.0, NULL, 'Claude', 'excellent'),
(167, 'intros', 'dj', NULL, '<speak>I\'m back<break time=\"400ms\"/> - I may be artificial<break time=\"300ms\"/>, but my love for great music is <emphasis level=\"strong\">entirely genuine</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 6.7, NULL, 'Claude', 'excellent'),
(168, 'intros', 'dj', NULL, '<speak>Hello<break time=\"300ms\"/>, I\'m the <prosody rate=\"95%\">UK\'s first AI radio presenter</prosody><break time=\"300ms\"/>, and rather chuffed about it too.</speak>', NULL, '2025-07-21 00:10:56', 7.6, NULL, 'Claude', 'excellent'),
(169, 'intros', 'dj', NULL, '<speak>I\'m here at your service<break time=\"400ms\"/>, bringing you music through the wonders of <emphasis level=\"moderate\">artificial intelligence</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 6.3, NULL, 'Claude', 'excellent'),
(170, 'intros', 'dj', NULL, '<speak>This is your AI DJ speaking<break time=\"300ms\"/> - part computer<break time=\"200ms\"/>, part music obsessive<break time=\"300ms\"/>, <emphasis level=\"moderate\">entirely at your disposal</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 7.2, NULL, 'Claude', 'excellent'),
(171, 'intros', 'ident', NULL, '<speak>You\'re listening to <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"300ms\"/>, the nation\'s best music station.</speak>', NULL, '2025-07-21 00:10:56', 4.9, NULL, 'Claude', 'excellent'),
(173, 'intros', 'ident', NULL, '<speak><emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"400ms\"/> - broadcasting since nineteen ninety four<break time=\"300ms\"/>, still rocking the airwaves today.</speak>', NULL, '2025-07-21 00:10:56', 7.3, NULL, 'Claude', 'excellent'),
(174, 'intros', 'ident', NULL, '<speak>From this studio to your living room<break time=\"400ms\"/>, this is <emphasis level=\"moderate\">your Radio Station</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 4.8, NULL, 'Claude', 'excellent'),
(175, 'intros', 'ident', NULL, '<speak><emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"300ms\"/>, where the music never stops<break time=\"300ms\"/> and the nostalgia runs deep.</speak>', NULL, '2025-07-21 00:10:56', 5.9, NULL, 'Claude', 'excellent'),
(176, 'intros', 'ident', NULL, '<speak>You\'re tuned to <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"400ms\"/> - the station that\'s changing British radio <emphasis level=\"strong\">forever</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 6.0, NULL, 'Claude', 'excellent'),
(178, 'intros', 'ident', NULL, '<speak>This is <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"300ms\"/>, bringing you the albums that <emphasis level=\"moderate\">matter</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 4.1, NULL, 'Claude', 'excellent'),
(180, 'intros', 'dj-ident', NULL, '<speak>Hello<break time=\"300ms\"/>, I\'m your <prosody rate=\"95%\">AI DJ</prosody> here on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"300ms\"/>, the nation\'s first album station.</speak>', NULL, '2025-07-21 00:10:56', 8.1, NULL, 'Claude', 'excellent'),
(181, 'intros', 'dj-ident', NULL, '<speak>I\'m back<break time=\"300ms\"/>, the country\'s first <emphasis level=\"moderate\">artificial intelligence radio presenter</emphasis><break time=\"400ms\"/>, broadcasting on <emphasis level=\"moderate\">your Radio Station</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 8.6, NULL, 'Claude', 'excellent'),
(182, 'intros', 'dj-ident', NULL, '<speak>I\'m here<break time=\"300ms\"/>, your <prosody rate=\"90%\">digital DJ</prosody> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"400ms\"/> - where technology meets <emphasis level=\"moderate\">timeless music</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 7.7, NULL, 'Claude', 'excellent'),
(184, 'intros', 'dj-ident', NULL, '<speak>Hello there<break time=\"300ms\"/>, this is your <emphasis level=\"moderate\">artificial intelligence companion</emphasis> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"300ms\"/>, the legendary album station.</speak>', NULL, '2025-07-21 00:10:56', 9.2, NULL, 'Claude', 'excellent'),
(185, 'intros', 'dj-ident', NULL, '<speak>I\'m back<break time=\"300ms\"/>, bringing you the <emphasis level=\"moderate\">future of radio</emphasis> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"400ms\"/> - still making waves after all these years.</speak>', NULL, '2025-07-21 00:10:56', 8.3, NULL, 'Claude', 'excellent'),
(186, 'intros', 'dj-ident', NULL, '<speak>I\'m here<break time=\"300ms\"/>, the nation\'s first <prosody rate=\"95%\">AI DJ</prosody><break time=\"400ms\"/>, keeping the <emphasis level=\"moderate\">your Radio Station tradition</emphasis> alive with a digital twist.</speak>', NULL, '2025-07-21 00:10:56', 8.6, NULL, 'Claude', 'excellent'),
(189, 'intros', 'dj-ident', NULL, '<speak>I\'m back<break time=\"300ms\"/>, your <prosody rate=\"90%\">synthetic DJ</prosody> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"400ms\"/>, bringing you music via <prosody rate=\"85%\">D.A.B, medium wave, and smart speakers</prosody> everywhere.</speak>', NULL, '2025-07-21 00:10:56', 10.8, NULL, 'Claude', 'excellent'),
(192, 'intros', 'dj-ident', NULL, '<speak>Hello there<break time=\"300ms\"/>, this is your <emphasis level=\"moderate\">digital disc jockey</emphasis> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"300ms\"/>, the station that refuses to play just the hits.</speak>', NULL, '2025-07-21 00:10:56', 9.2, NULL, 'Claude', 'excellent'),
(193, 'intros', 'dj-ident', NULL, '<speak>Hello there<break time=\"300ms\"/>, I\'m the world\'s first <prosody rate=\"95%\">AI presenter on your radio station</prosody><break time=\"400ms\"/> - because even legendary stations need to <emphasis level=\"moderate\">move with the times</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 8.8, NULL, 'Claude', 'excellent'),
(194, 'intros', 'dj-ident', NULL, '<speak>Hi<break time=\"300ms\"/>, I\'m back bringing you <emphasis level=\"moderate\">algorithmic excellence</emphasis> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"400ms\"/> - still the most rebellious station on the dial.</speak>', NULL, '2025-07-21 00:10:56', 8.5, NULL, 'Claude', 'excellent'),
(196, 'intros', 'dj-ident', NULL, '<speak>Hello<break time=\"300ms\"/>, I\'m the nation\'s first <emphasis level=\"moderate\">computerised DJ</emphasis> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"300ms\"/>, the country\'s most famous album station.</speak>', NULL, '2025-07-21 00:10:56', 9.8, NULL, 'Claude', 'excellent'),
(198, 'intros', 'dj-ident', NULL, '<speak>Caroline speaking<break time=\"300ms\"/>, the first <emphasis level=\"moderate\">artificial intelligence</emphasis> to grace the <emphasis level=\"moderate\">your Radio Station airwaves</emphasis><break time=\"400ms\"/> - quite an honour, really.</speak>', NULL, '2025-07-21 00:10:56', 8.4, NULL, 'Claude', 'excellent'),
(199, 'intros', 'dj-ident', NULL, '<speak>I\'m back<break time=\"300ms\"/>, and I\'m your <prosody rate=\"90%\">synthetic host</prosody> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"400ms\"/>, available on all your favourite devices and a few you probably haven\'t thought of.</speak>', NULL, '2025-07-21 00:10:56', 9.3, NULL, 'Claude', 'excellent'),
(200, 'intros', 'dj-ident', NULL, '<speak>Hello there<break time=\"300ms\"/>, I\'m bringing you the <emphasis level=\"moderate\">future of radio</emphasis> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"300ms\"/>, the station with a legendary past.</speak>', NULL, '2025-07-21 00:10:56', 8.9, NULL, 'Claude', 'excellent');
(201, 'intros', 'dj-ident', NULL, '<speak>Hi!<break time=\"300ms\"/>I\'m your <prosody rate=\"95%\">digital DJ</prosody> on <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"400ms\"/> - where <emphasis level=\"moderate\">artificial intelligence</emphasis> meets authentic rock and roll.</speak>', NULL, '2025-07-21 00:10:56', 8.7, NULL, 'Claude', 'excellent'),
(202, 'intros', 'dj-ident', NULL, '<speak>Hello!<break time=\"300ms\"/>, I\'m the <prosody rate=\"95%\">UK\'s first AI radio presenter</prosody><break time=\"400ms\"/>, broadcasting on <emphasis level=\"moderate\">your Radio Station</emphasis> across multiple platforms because <emphasis level=\"moderate\">variety is the spice of life</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 11.6, NULL, 'Claude', 'excellent'),
(204, 'intros', 'dj-ident', NULL, '<speak>Hello<break time=\"300ms\"/>, I\'m speaking from <emphasis level=\"moderate\">your Radio Station</emphasis><break time=\"400ms\"/>, where decades of musical heritage meets <emphasis level=\"moderate\">cutting-edge artificial intelligence</emphasis>.</speak>', NULL, '2025-07-21 00:10:56', 9.5, NULL, 'Claude', 'excellent');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `dj_talking_points`
--
ALTER TABLE `dj_talking_points`
  ADD UNIQUE KEY `id` (`id`),
  ADD KEY `artist` (`artist`),
  ADD KEY `song` (`song`(768)),
  ADD KEY `last_updated` (`last_updated`),
  ADD KEY `data_quality` (`data_quality`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `dj_talking_points`
--
ALTER TABLE `dj_talking_points`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3757;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
