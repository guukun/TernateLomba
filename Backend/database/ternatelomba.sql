-- TernateLomba 2.0 | Skema instalasi baru (12 tabel + 4 kategori)
-- MariaDB / MySQL; berdasarkan dump aplikasi dan perbaikan skema.
-- TIDAK berisi pengguna, password, token, pendaftaran, maupun data pribadi.
-- HANYA impor ke database BARU/KOSONG. Jangan impor ke database aktif.

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `ternatelomba`
--

-- --------------------------------------------------------

--
-- Table structure for table `chat_pesan`
--

CREATE TABLE `chat_pesan` (
  `id_pesan` bigint(20) UNSIGNED NOT NULL,
  `id_lomba` int(10) UNSIGNED NOT NULL,
  `id_user` int(10) UNSIGNED NOT NULL,
  `isi_pesan` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chat_pesan`
--

-- --------------------------------------------------------

--
-- Table structure for table `favorit_lomba`
--

CREATE TABLE `favorit_lomba` (
  `id_favorit` int(10) UNSIGNED NOT NULL,
  `id_user` int(10) UNSIGNED NOT NULL,
  `id_lomba` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `form_field`
--

CREATE TABLE `form_field` (
  `id_field` int(10) UNSIGNED NOT NULL,
  `id_pengajuan` int(10) UNSIGNED NOT NULL,
  `nama_field` varchar(100) NOT NULL,
  `placeholder` varchar(255) DEFAULT NULL,
  `tipe_field` enum('Text','Textarea','Number','Dropdown','Date','File','Email','Phone') NOT NULL DEFAULT 'Text',
  `opsi_field` longtext DEFAULT NULL,
  `wajib` tinyint(1) NOT NULL DEFAULT 1,
  `urutan` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `form_field`
--

-- --------------------------------------------------------

--
-- Table structure for table `informasi_lomba`
--

CREATE TABLE `informasi_lomba` (
  `id_informasi` int(10) UNSIGNED NOT NULL,
  `id_pengajuan` int(10) UNSIGNED NOT NULL,
  `kelompok_informasi` varchar(100) NOT NULL DEFAULT 'Informasi Tambahan',
  `label_informasi` varchar(150) NOT NULL,
  `nilai_informasi` text NOT NULL,
  `urutan` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jawaban_pendaftaran`
--

CREATE TABLE `jawaban_pendaftaran` (
  `id_jawaban` int(10) UNSIGNED NOT NULL,
  `id_pendaftaran` int(10) UNSIGNED NOT NULL,
  `id_field` int(10) UNSIGNED NOT NULL,
  `jawaban` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `jawaban_pendaftaran`
--

-- --------------------------------------------------------

--
-- Table structure for table `kategori_lomba`
--

CREATE TABLE `kategori_lomba` (
  `id_kategori` int(10) UNSIGNED NOT NULL,
  `nama_kategori` varchar(100) NOT NULL,
  `deskripsi_kategori` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Kategori awal (bukan data pengguna).
INSERT INTO `kategori_lomba` (`id_kategori`, `nama_kategori`, `deskripsi_kategori`) VALUES
(1, 'Akademik', 'Lomba karya tulis, olimpiade, dan debat'),
(2, 'Olahraga', 'Lomba cabang olahraga'),
(3, 'Seni', 'Lomba musik, tari, lukis, dan fotografi'),
(4, 'Teknologi', 'Lomba coding, desain, dan inovasi');


--
-- Dumping data for table `kategori_lomba`
--

-- --------------------------------------------------------

--
-- Table structure for table `lomba`
--

CREATE TABLE `lomba` (
  `id_lomba` int(10) UNSIGNED NOT NULL,
  `id_pengajuan` int(10) UNSIGNED NOT NULL,
  `status_lomba` enum('Draft','Aktif','Selesai') NOT NULL DEFAULT 'Draft',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `lomba`
--

-- --------------------------------------------------------

--
-- Table structure for table `lomba_penghentian`
--

CREATE TABLE `lomba_penghentian` (
  `id_penghentian` bigint(20) UNSIGNED NOT NULL,
  `id_lomba` int(10) UNSIGNED NOT NULL,
  `id_admin` int(10) UNSIGNED NOT NULL,
  `jenis_tindakan` enum('Batalkan','Hentikan') NOT NULL DEFAULT 'Hentikan',
  `alasan` text NOT NULL,
  `dihentikan_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifikasi`
--

CREATE TABLE `notifikasi` (
  `id_notifikasi` int(10) UNSIGNED NOT NULL,
  `id_user` int(10) UNSIGNED NOT NULL,
  `judul` varchar(150) NOT NULL,
  `pesan` text NOT NULL,
  `tipe` varchar(30) NOT NULL DEFAULT 'info',
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`data`)),
  `dibaca_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifikasi`
--

-- --------------------------------------------------------

--
-- Table structure for table `pendaftaran`
--

CREATE TABLE `pendaftaran` (
  `id_pendaftaran` int(10) UNSIGNED NOT NULL,
  `id_lomba` int(10) UNSIGNED NOT NULL,
  `id_user` int(10) UNSIGNED NOT NULL,
  `tanggal_pendaftaran` datetime NOT NULL DEFAULT current_timestamp(),
  `status_pendaftaran` enum('Draft','Menunggu','Diterima','Ditolak') NOT NULL DEFAULT 'Draft',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pendaftaran`
--

-- --------------------------------------------------------

--
-- Table structure for table `pengajuan_lomba`
--

CREATE TABLE `pengajuan_lomba` (
  `id_pengajuan` int(10) UNSIGNED NOT NULL,
  `id_user` int(10) UNSIGNED NOT NULL,
  `id_kategori` int(10) UNSIGNED NOT NULL,
  `nama_lomba` varchar(200) NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `persyaratan` text DEFAULT NULL,
  `tanggal_mulai_pendaftaran` date DEFAULT NULL,
  `tanggal_pelaksanaan` date DEFAULT NULL,
  `tanggal_selesai_pelaksanaan` date DEFAULT NULL,
  `batas_pendaftaran` date DEFAULT NULL,
  `lokasi_pendaftaran` varchar(255) DEFAULT NULL,
  `metode_pelaksanaan` enum('Online','Offline') DEFAULT NULL,
  `detail_pelaksanaan` varchar(500) DEFAULT NULL,
  `biaya` decimal(12,2) NOT NULL DEFAULT 0.00,
  `hadiah` text DEFAULT NULL,
  `kuota_peserta` int(10) UNSIGNED DEFAULT NULL,
  `kontak_penyelenggara` varchar(100) DEFAULT NULL,
  `poster_lomba` varchar(255) DEFAULT NULL,
  `status_pengajuan` enum('Menunggu','Disetujui','Ditolak') NOT NULL DEFAULT 'Menunggu',
  `catatan_admin` text DEFAULT NULL,
  `tanggal_pengajuan` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pengajuan_lomba`
--

-- --------------------------------------------------------


-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id_user` int(10) UNSIGNED NOT NULL,
  `username` varchar(255) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('User','Penyelenggara','Administrator') NOT NULL DEFAULT 'User',
  `foto_profil` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL,
  `api_token_hash` char(64) DEFAULT NULL,
  `api_token_expires_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

--
-- Indexes for dumped tables
--

--
-- Indexes for table `chat_pesan`
--
ALTER TABLE `chat_pesan`
  ADD PRIMARY KEY (`id_pesan`),
  ADD KEY `idx_chat_lomba_urut` (`id_lomba`,`id_pesan`),
  ADD KEY `idx_chat_pengirim` (`id_user`);

--
-- Indexes for table `favorit_lomba`
--
ALTER TABLE `favorit_lomba`
  ADD PRIMARY KEY (`id_favorit`),
  ADD UNIQUE KEY `uq_favorit_user_lomba` (`id_user`,`id_lomba`),
  ADD KEY `fk_favorit_lomba` (`id_lomba`);

--
-- Indexes for table `form_field`
--
ALTER TABLE `form_field`
  ADD PRIMARY KEY (`id_field`),
  ADD KEY `idx_field_lomba` (`id_pengajuan`);

--
-- Indexes for table `informasi_lomba`
--
ALTER TABLE `informasi_lomba`
  ADD PRIMARY KEY (`id_informasi`),
  ADD KEY `idx_info_pengajuan_kelompok_urutan` (`id_pengajuan`,`kelompok_informasi`,`urutan`);

--
-- Indexes for table `jawaban_pendaftaran`
--
ALTER TABLE `jawaban_pendaftaran`
  ADD PRIMARY KEY (`id_jawaban`),
  ADD UNIQUE KEY `uq_jawaban_pendaftaran_field` (`id_pendaftaran`,`id_field`),
  ADD KEY `idx_jawaban_id_field` (`id_field`);

--
-- Indexes for table `kategori_lomba`
--
ALTER TABLE `kategori_lomba`
  ADD PRIMARY KEY (`id_kategori`),
  ADD UNIQUE KEY `uq_kategori_nama` (`nama_kategori`);

--
-- Indexes for table `lomba`
--
ALTER TABLE `lomba`
  ADD PRIMARY KEY (`id_lomba`),
  ADD UNIQUE KEY `uq_lomba_pengajuan` (`id_pengajuan`);

--
-- Indexes for table `lomba_penghentian`
--
ALTER TABLE `lomba_penghentian`
  ADD PRIMARY KEY (`id_penghentian`),
  ADD UNIQUE KEY `lomba_penghentian_id_lomba_unique` (`id_lomba`),
  ADD KEY `lomba_penghentian_id_admin_index` (`id_admin`);

--
-- Indexes for table `notifikasi`
--
ALTER TABLE `notifikasi`
  ADD PRIMARY KEY (`id_notifikasi`),
  ADD KEY `notifikasi_user_dibaca_index` (`id_user`,`dibaca_at`);

--
-- Indexes for table `pendaftaran`
--
ALTER TABLE `pendaftaran`
  ADD PRIMARY KEY (`id_pendaftaran`),
  ADD UNIQUE KEY `uq_pendaftaran_lomba_user` (`id_lomba`,`id_user`),
  ADD KEY `idx_pendaftaran_user` (`id_user`);

--
-- Indexes for table `pengajuan_lomba`
--
ALTER TABLE `pengajuan_lomba`
  ADD PRIMARY KEY (`id_pengajuan`),
  ADD KEY `idx_pengajuan_user` (`id_user`),
  ADD KEY `idx_pengajuan_kategori` (`id_kategori`);


--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id_user`),
  ADD UNIQUE KEY `uq_users_nama_pengguna` (`username`),
  ADD UNIQUE KEY `users_api_token_hash_unique` (`api_token_hash`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `chat_pesan`
--
ALTER TABLE `chat_pesan`
  MODIFY `id_pesan` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `favorit_lomba`
--
ALTER TABLE `favorit_lomba`
  MODIFY `id_favorit` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `form_field`
--
ALTER TABLE `form_field`
  MODIFY `id_field` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `informasi_lomba`
--
ALTER TABLE `informasi_lomba`
  MODIFY `id_informasi` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jawaban_pendaftaran`
--
ALTER TABLE `jawaban_pendaftaran`
  MODIFY `id_jawaban` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `kategori_lomba`
--
ALTER TABLE `kategori_lomba`
  MODIFY `id_kategori` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `lomba`
--
ALTER TABLE `lomba`
  MODIFY `id_lomba` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lomba_penghentian`
--
ALTER TABLE `lomba_penghentian`
  MODIFY `id_penghentian` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifikasi`
--
ALTER TABLE `notifikasi`
  MODIFY `id_notifikasi` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pendaftaran`
--
ALTER TABLE `pendaftaran`
  MODIFY `id_pendaftaran` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pengajuan_lomba`
--
ALTER TABLE `pengajuan_lomba`
  MODIFY `id_pengajuan` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;


--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id_user` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `chat_pesan`
--
ALTER TABLE `chat_pesan`
  ADD CONSTRAINT `fk_chat_lomba` FOREIGN KEY (`id_lomba`) REFERENCES `lomba` (`id_lomba`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_chat_pengirim` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE;

--
-- Constraints for table `favorit_lomba`
--
ALTER TABLE `favorit_lomba`
  ADD CONSTRAINT `fk_favorit_lomba` FOREIGN KEY (`id_lomba`) REFERENCES `lomba` (`id_lomba`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_favorit_user` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE;

--
-- Constraints for table `form_field`
--
ALTER TABLE `form_field`
  ADD CONSTRAINT `fk_form_field_pengajuan` FOREIGN KEY (`id_pengajuan`) REFERENCES `pengajuan_lomba` (`id_pengajuan`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `informasi_lomba`
--
ALTER TABLE `informasi_lomba`
  ADD CONSTRAINT `fk_informasi_lomba_pengajuan` FOREIGN KEY (`id_pengajuan`) REFERENCES `pengajuan_lomba` (`id_pengajuan`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `jawaban_pendaftaran`
--
ALTER TABLE `jawaban_pendaftaran`
  ADD CONSTRAINT `fk_jawaban_form_field` FOREIGN KEY (`id_field`) REFERENCES `form_field` (`id_field`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_jawaban_pendaftaran` FOREIGN KEY (`id_pendaftaran`) REFERENCES `pendaftaran` (`id_pendaftaran`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `lomba`
--
ALTER TABLE `lomba`
  ADD CONSTRAINT `fk_lomba_pengajuan` FOREIGN KEY (`id_pengajuan`) REFERENCES `pengajuan_lomba` (`id_pengajuan`) ON UPDATE CASCADE;

--
-- Constraints for table `lomba_penghentian`
--
ALTER TABLE `lomba_penghentian`
  ADD CONSTRAINT `fk_penghentian_lomba` FOREIGN KEY (`id_lomba`) REFERENCES `lomba` (`id_lomba`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_penghentian_admin` FOREIGN KEY (`id_admin`) REFERENCES `users` (`id_user`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `notifikasi`
--
ALTER TABLE `notifikasi`
  ADD CONSTRAINT `notifikasi_id_user_foreign` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE;

--
-- Constraints for table `pendaftaran`
--
ALTER TABLE `pendaftaran`
  ADD CONSTRAINT `fk_pendaftaran_lomba` FOREIGN KEY (`id_lomba`) REFERENCES `lomba` (`id_lomba`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pendaftaran_user` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `pengajuan_lomba`
--
ALTER TABLE `pengajuan_lomba`
  ADD CONSTRAINT `fk_pengajuan_kategori` FOREIGN KEY (`id_kategori`) REFERENCES `kategori_lomba` (`id_kategori`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_pengajuan_user` FOREIGN KEY (`id_user`) REFERENCES `users` (`id_user`) ON UPDATE CASCADE;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
