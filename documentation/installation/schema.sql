-- phpMyAdmin SQL Dump
-- version 5.0.0-dev
-- https://www.phpmyadmin.net/
--
-- Host: 95.216.176.70:3307
-- Generation Time: May 24, 2021 at 03:38 PM
-- Server version: 10.1.34-MariaDB-0ubuntu0.18.04.1
-- PHP Version: 7.2.10-0ubuntu0.18.04.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `genular`
--

-- --------------------------------------------------------

--
-- Table structure for table `dataset_proportions`
--

CREATE TABLE `dataset_proportions` (
  `id` int(11) NOT NULL,
  `drid` int(11) DEFAULT NULL COMMENT 'Dataset Resamples ID',
  `class_name` varchar(255) DEFAULT NULL COMMENT 'Name of the class that is analized',
  `proportion_class_name` varchar(255) DEFAULT NULL,
  `feature_set_type` tinyint(4) DEFAULT NULL COMMENT '1 - Training\n2 - Testing\n3 - Validation',
  `measurement_type` tinyint(4) DEFAULT NULL COMMENT '1 - number\n2 - percentage\n3 - median\n4 - min\n5 - max\n6 - number of unique values\n7 - number of all values ',
  `value` varchar(255) DEFAULT NULL COMMENT 'proportion_class_name remapped value',
  `result` float DEFAULT NULL COMMENT 'Calculated number value',
  `created` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Proportions of Outcome and Classes Variables for specific dataset resample in Percentage and numeric format';

-- --------------------------------------------------------

--
-- Table structure for table `dataset_queue`
--

CREATE TABLE `dataset_queue` (
  `id` int(11) NOT NULL,
  `uid` int(11) DEFAULT NULL COMMENT 'User ID',
  `ufid` int(11) DEFAULT NULL COMMENT 'Users Files ID that is in question for processing',
  `name` varchar(255) DEFAULT NULL COMMENT 'Queue name',
  `uniqueHash` char(64) DEFAULT NULL COMMENT 'MD5 hash of :\nuserID\nselected header values\nselected files IDs\npackages,\nextraction\nfeature_selection',
  `selectedOptions` longtext COMMENT 'JSON encoded list of features, outcomes and classes to analyze:\nname\ndataType\nitemType\ntotalNaValues\nunique',
  `impute` tinyint(6) DEFAULT '0' COMMENT 'Should we do additional inputation on dataset.\nmedianImpute, bagImpute, knnImpute',
  `extraction` tinyint(4) DEFAULT '0' COMMENT 'Should we do array intersection',
  `backwardSelection` tinyint(4) DEFAULT '0' COMMENT 'Are we doing recursive feature elimination.\n0 - No\n1 - Yes',
  `sparsity` float DEFAULT NULL,
  `packages` longtext COMMENT 'JSON - Packages/Models to use in the process with their tunning parametars\n{\n	packageID: \n	serverGroup:\n}',
  `status` tinyint(6) DEFAULT NULL COMMENT '0 Created\n1 User confirmed - and resamples active\n2 User canceled - Inactive\n3 Marked for processing - cron job must pick it up\n4 R Processing\n5 R Finished - Sucess\n6 R Finished - Errors\n7 User Paused\n8 User resumed',
  `processing_time` int(11) DEFAULT '0' COMMENT 'Total processing time - miliseconds',
  `servers_total` int(11) DEFAULT '0' COMMENT 'Total number of created cloud servers that needs to do processing',
  `created` datetime DEFAULT NULL COMMENT 'Initial Created time',
  `created_ip_address` varchar(15) DEFAULT NULL,
  `updated` datetime DEFAULT NULL COMMENT 'Updated time',
  `updated_ip_address` varchar(15) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Main Model Processing JOB/task queue';

-- --------------------------------------------------------

--
-- Table structure for table `dataset_resamples`
--

CREATE TABLE `dataset_resamples` (
  `id` int(11) NOT NULL,
  `dqid` int(11) DEFAULT NULL COMMENT 'Dataset Queue ID',
  `ufid` int(11) DEFAULT NULL COMMENT 'User File ID, if Extraction is on new Files are genereated from main File in Queue',
  `ufid_train` int(11) DEFAULT NULL COMMENT 'Train set User File ID',
  `ufid_test` int(11) DEFAULT NULL COMMENT 'Test set User File ID',
  `data_source` tinyint(6) DEFAULT NULL COMMENT 'What kind of resmaple is this?\n0 - shadow  - we use it for RFE or something else - it is not displayed to user\n1 - normal - use it to display it to user\n',
  `samples_total` int(11) DEFAULT NULL COMMENT 'Total samples in Set',
  `samples_training` int(11) DEFAULT NULL COMMENT 'Total samples in Training Set',
  `samples_testing` int(11) DEFAULT NULL COMMENT 'Total samples in Testing Set',
  `features_total` int(11) DEFAULT NULL COMMENT 'Total number of Features',
  `selectedOptions` longtext COMMENT 'JSON Remapped Predictor Variables for specific intersection if extraction is used',
  `datapoints` int(11) DEFAULT NULL COMMENT '(Features * rows)',
  `problemType` tinyint(6) DEFAULT NULL COMMENT 'Type of problem:\n1- classification\n2- regression\n3- nn',
  `status` tinyint(6) DEFAULT NULL COMMENT '0 Created\n1 Deselected\n2 Selected\n3 R train/test partitions created\n4 R cron started processing\n5 Finished Success\n6 Finished Errors',
  `servers_finished` int(11) DEFAULT '0' COMMENT 'Total number of cloud servers that finished processing',
  `processing_time` int(11) DEFAULT NULL COMMENT 'Total processing time in miliseconds',
  `error` longtext COMMENT 'Errors regarding dataset. Zero Variance etc..',
  `created` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'Dataset Sample Creation Time',
  `updated` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Datasets automaticaly made from specific dataset that is in queue if extraction is cecked,\ntaan intersection of data is used. Usefull in case of missing data';

-- --------------------------------------------------------

--
-- Table structure for table `dataset_resamples_components`
--

CREATE TABLE `dataset_resamples_components` (
  `id` int(11) NOT NULL,
  `dqid` int(11) DEFAULT NULL COMMENT 'Dataset Queue ID',
  `drid` int(11) DEFAULT NULL COMMENT 'Dataset Resamples ID',
  `pre_process_type` varchar(64) DEFAULT NULL COMMENT 'PreProcessing type: pca, ice ..',
  `feature_name` varchar(255) DEFAULT NULL COMMENT 'Remmaped name of the column',
  `component_name` varchar(255) DEFAULT NULL COMMENT 'Original user given name of the class',
  `rank_in_component` varchar(255) DEFAULT NULL COMMENT 'The proportion of variation retained by the principal components ',
  `created` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Resample component mappings if PCA or ICE preProcessing is used';

-- --------------------------------------------------------

--
-- Table structure for table `dataset_resamples_mappings`
--

CREATE TABLE `dataset_resamples_mappings` (
  `id` int(11) NOT NULL,
  `dqid` int(11) DEFAULT NULL COMMENT 'Dataset Queue ID',
  `drid` int(11) DEFAULT NULL COMMENT 'Dataset Resamples ID',
  `class_column` varchar(255) DEFAULT NULL COMMENT 'This should basically be parent mappings ID, \nbut since this is not fully implemented this is not MAIN column value',
  `class_type` tinyint(6) DEFAULT NULL COMMENT '1 - Column name\n2 - Column Value',
  `class_original` varchar(255) DEFAULT NULL COMMENT 'Original user given name of the class',
  `class_remapped` varchar(255) DEFAULT NULL COMMENT 'Remmaped value of the class',
  `class_possition` int(11) DEFAULT NULL COMMENT 'If Type 1 - Possition of the column\n',
  `created` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Here we are saving remapping related to some resample. Like for example column names mappings or colum values mapping.\nMapping are done in order to santizie user input';

-- --------------------------------------------------------

--
-- Table structure for table `models`
--

CREATE TABLE `models` (
  `id` int(11) NOT NULL,
  `drid` int(11) DEFAULT NULL COMMENT 'Dataset Resample ID',
  `ufid` int(11) DEFAULT NULL COMMENT 'users_files_id - where is model data saved',
  `mpid` int(11) DEFAULT NULL COMMENT 'Model Packages ID',
  `mv_hash` char(32) DEFAULT NULL COMMENT 'models_variables MD5 signature hash',
  `status` tinyint(6) DEFAULT NULL COMMENT 'Analysis status\n0 - Model Failure\n1- Sucess',
  `error` longtext COMMENT 'JSON encoded array of errors',
  `training_time` int(11) DEFAULT NULL COMMENT 'Only model training time - miliseconds',
  `processing_time` int(11) DEFAULT NULL COMMENT 'Total models processing time. Training, testing etc.. - miliseconds',
  `credits` int(11) DEFAULT NULL COMMENT 'Used credits in specific analysis',
  `created` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'time created',
  `updated` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Processed Models for Specific Dataset Resample';

-- --------------------------------------------------------

--
-- Table structure for table `models_packages`
--

CREATE TABLE `models_packages` (
  `id` int(11) NOT NULL,
  `internal_id` varchar(255) DEFAULT NULL COMMENT 'caret ID - method name',
  `label` varchar(255) DEFAULT NULL COMMENT 'Human readible label',
  `dependencies` longtext COMMENT 'JSON - R librarys needed to load for model processing',
  `classification` tinyint(4) DEFAULT '0' COMMENT '1 - yes\n0 - no',
  `regression` tinyint(4) DEFAULT '0' COMMENT '1 - yes\n0 - no',
  `tags` longtext COMMENT 'JSON list of model tags',
  `tuning_parameters` longtext COMMENT 'JSON - model tuning parametars',
  `citations` longtext COMMENT 'JSON of citations for all libraries needed for this model',
  `licenses` longtext COMMENT 'JSON of licenses for all libraries needed for this model',
  `time_per_million` int(11) DEFAULT NULL COMMENT 'Average Time in miliseconds needed to process per milion datapoints\ndataponts = columns x rows',
  `documentation` text COMMENT '{\npackageName: "",\npackageVersion: "",\nhtml_content: ""\n}',
  `r_version` float DEFAULT NULL,
  `installed` tinyint(4) DEFAULT NULL COMMENT 'Is package installed or not',
  `created` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='List of ALL avaliable Packages on the system';

-- --------------------------------------------------------

--
-- Table structure for table `models_performance`
--

CREATE TABLE `models_performance` (
  `id` int(11) NOT NULL,
  `mid` int(11) DEFAULT NULL COMMENT 'Model Details ID',
  `mpvid` int(11) DEFAULT NULL COMMENT 'Model Performance Variables ID',
  `prefValue` varchar(255) DEFAULT NULL COMMENT 'Value',
  `created` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Processed Model Variables for specific Model - AUC, Accuracy etc..';

-- --------------------------------------------------------

--
-- Table structure for table `models_performance_variables`
--

CREATE TABLE `models_performance_variables` (
  `id` int(11) NOT NULL,
  `value` varchar(255) DEFAULT NULL COMMENT 'Model Details ID',
  `created` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='IDs of preference Value, used in model_performance';

-- --------------------------------------------------------

--
-- Table structure for table `models_variables`
--

CREATE TABLE `models_variables` (
  `id` int(11) NOT NULL,
  `mid` int(11) DEFAULT NULL COMMENT 'Model Details ID',
  `feature_name` varchar(255) DEFAULT NULL COMMENT 'Name of analized Feature as in CSV',
  `score_perc` tinyint(6) DEFAULT NULL COMMENT 'Inpact Score of feature on this model in percentage',
  `score_no` float DEFAULT NULL COMMENT 'Inpact Score of feature on this model in internal model metrix',
  `rank` tinyint(6) DEFAULT NULL COMMENT 'Inpact Score of feature on this model in numbers',
  `created` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Variable Importance Scores for processed models';

-- --------------------------------------------------------

--
-- Table structure for table `organization`
--

CREATE TABLE `organization` (
  `id` int(11) NOT NULL,
  `invite_code` varchar(255) DEFAULT NULL COMMENT 'Organization Invite Code for Users to Join',
  `salt` char(16) DEFAULT NULL,
  `status` tinyint(1) DEFAULT NULL,
  `created` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Main Organization Table';

-- --------------------------------------------------------

--
-- Table structure for table `organization_details`
--

CREATE TABLE `organization_details` (
  `id` int(11) NOT NULL,
  `oid` int(11) DEFAULT NULL COMMENT 'Organization ID',
  `name` varchar(255) DEFAULT NULL COMMENT 'Organization Name',
  `sector` varchar(255) DEFAULT NULL COMMENT 'Organization Sector',
  `phone` varchar(255) DEFAULT NULL COMMENT 'Office Phone',
  `email` varchar(255) DEFAULT NULL COMMENT 'Office Email',
  `website` varchar(255) DEFAULT NULL COMMENT 'official Website',
  `address` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `zip` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Details related to specific Organization';

-- --------------------------------------------------------

--
-- Table structure for table `public_databases`
--

CREATE TABLE `public_databases` (
  `id` int(11) NOT NULL,
  `uid` int(11) DEFAULT NULL COMMENT 'User ID of the dataset uploader',
  `title` varchar(255) DEFAULT NULL,
  `description` text COMMENT 'Description of the dataset.\nMust have following sections: Description, Format, Source',
  `format` text,
  `source` text,
  `references` text,
  `example` text COMMENT 'This column must contain CSV header and 5 rows of values',
  `rows` int(11) DEFAULT NULL COMMENT 'Total number of rows in the dataset',
  `columns` int(11) DEFAULT NULL COMMENT 'Number of columns in the dataset',
  `hash` char(32) DEFAULT NULL COMMENT 'MD5 hash of the data csv file, this hash is also filename',
  `sparsity` float DEFAULT NULL COMMENT 'Sparsity of a dataframe',
  `updated` datetime DEFAULT CURRENT_TIMESTAMP,
  `created` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Database of example datasets that once can use';

-- --------------------------------------------------------

--
-- Table structure for table `public_databases_buckets`
--

CREATE TABLE `public_databases_buckets` (
  `id` int(11) NOT NULL,
  `pdmid` int(11) DEFAULT NULL,
  `internal_id` int(11) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `variable` varchar(255) DEFAULT NULL,
  `mesurment_value` int(11) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Bucket calculation for databases';

-- --------------------------------------------------------

--
-- Table structure for table `public_databases_mappings`
--

CREATE TABLE `public_databases_mappings` (
  `id` int(11) NOT NULL,
  `pdid` int(11) DEFAULT NULL,
  `original` varchar(255) DEFAULT NULL,
  `position` int(11) DEFAULT NULL,
  `remapped` varchar(255) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Column mappings for the dataset';

-- --------------------------------------------------------

--
-- Table structure for table `public_databases_statistics`
--

CREATE TABLE `public_databases_statistics` (
  `id` int(11) NOT NULL,
  `pdmid` int(11) DEFAULT NULL,
  `variable` varchar(45) DEFAULT NULL,
  `mesurment_value` varchar(45) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Column statistics for the given dataset';

-- --------------------------------------------------------

--
-- Table structure for table `public_databases_votes`
--

CREATE TABLE `public_databases_votes` (
  `id` int(11) NOT NULL,
  `pdid` int(11) DEFAULT NULL COMMENT 'Public Databases ID',
  `uid` int(11) DEFAULT NULL,
  `direction` tinyint(1) DEFAULT NULL COMMENT 'Vote direction. 1/-1',
  `updated` datetime DEFAULT CURRENT_TIMESTAMP,
  `created` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Upvote/Downvote table for databases';

-- --------------------------------------------------------

--
-- Table structure for table `servers`
--

CREATE TABLE `servers` (
  `id` int(11) NOT NULL,
  `server_id` int(11) DEFAULT NULL COMMENT 'Internal server ID / Hatzner',
  `server_name` varchar(255) DEFAULT NULL COMMENT 'Internal server name - string ID',
  `server_public_net_ipv4_ipv4` int(11) DEFAULT NULL COMMENT 'IP Adress of the server',
  `server_public_net_ipv4_dns_ptr` varchar(255) DEFAULT NULL COMMENT 'Server rDNS record',
  `server_server_type_cores` int(11) DEFAULT NULL COMMENT 'Total number of CPU cores',
  `server_server_type_memory` int(11) DEFAULT NULL COMMENT 'Server memory RAM in GB',
  `server_server_type_prices_hourly` float DEFAULT NULL COMMENT 'Gross Price per Hour of server',
  `action_root_password` varchar(255) DEFAULT NULL COMMENT 'Server root Password',
  `server_datacenter_id` int(11) DEFAULT NULL,
  `server_datacenter_location_id` int(11) DEFAULT NULL,
  `server_image_id` int(11) DEFAULT NULL,
  `server_image_created_from_id` int(11) DEFAULT NULL,
  `node_type` int(11) DEFAULT NULL COMMENT '1 - analysis - main cron task\n2 - plots - genaration of plots and data wrangling\n',
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(255) DEFAULT NULL,
  `password` char(64) DEFAULT NULL,
  `salt` char(16) DEFAULT NULL,
  `validation_hash` char(32) DEFAULT NULL COMMENT 'Email Validation hash',
  `email_status` tinyint(1) DEFAULT NULL COMMENT '1 - Confirmed\n0 - Unconfirmed',
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Main Users Table';

-- --------------------------------------------------------

--
-- Table structure for table `users_apps`
--

CREATE TABLE `users_apps` (
  `id` int(11) NOT NULL,
  `uid` int(11) DEFAULT NULL COMMENT 'User ID',
  `name_space` varchar(45) DEFAULT NULL COMMENT 'Application namespace',
  `order` tinyint(6) DEFAULT NULL COMMENT 'App order on Frontend',
  `default` tinyint(4) DEFAULT NULL COMMENT 'Load Initially',
  `enabled` tinyint(4) DEFAULT NULL COMMENT 'Is enabled',
  `created` datetime DEFAULT NULL COMMENT 'Time Created'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Enabled Apps for specific User, modules';

-- --------------------------------------------------------

--
-- Table structure for table `users_details`
--

CREATE TABLE `users_details` (
  `id` int(11) NOT NULL,
  `uid` int(11) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `account_type` tinyint(1) DEFAULT NULL COMMENT '1 - Global Administrator\n2 - User\n3 - Organization Administrator\n4 - Organization User',
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='All details regardion to specific User';

-- --------------------------------------------------------

--
-- Table structure for table `users_files`
--

CREATE TABLE `users_files` (
  `id` int(11) NOT NULL,
  `uid` int(11) DEFAULT NULL COMMENT 'User ID',
  `ufsid` int(11) DEFAULT NULL COMMENT 'users_file_servers_id connection, if is NULL default is used',
  `item_type` tinyint(6) DEFAULT NULL COMMENT '1 - user uploaded the file\n2 - system created file (cron, data partitions etc.)',
  `file_path` varchar(255) DEFAULT NULL COMMENT 'Full path to the file with a filename, without base directory',
  `filename` char(32) DEFAULT NULL COMMENT 'MD5 safe filename ',
  `display_filename` varchar(255) DEFAULT NULL COMMENT 'Display filename',
  `size` int(11) DEFAULT '0' COMMENT 'Filesize in bytes ot the original file not gzipped one',
  `extension` varchar(25) DEFAULT NULL COMMENT 'file extension',
  `mime_type` varchar(75) DEFAULT NULL,
  `details` longtext COMMENT 'File details currently in following format:\n{\n	"header": {\n		"original": "",\n		"formatted": [{"original":"pregnant","position":0,"remapped":"column0"}]\n	}\n}',
  `file_hash` char(64) DEFAULT NULL COMMENT 'SHA256 hash of original file not gzipped one',
  `created` datetime DEFAULT NULL COMMENT 'timestamp',
  `updated` datetime DEFAULT NULL COMMENT 'timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Filestructure Table for all block storage Objects';

-- --------------------------------------------------------

--
-- Table structure for table `users_files_servers`
--

CREATE TABLE `users_files_servers` (
  `id` int(11) NOT NULL,
  `adapter_configuration` blob,
  `files_count` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Server mapping for users_files table';

-- --------------------------------------------------------

--
-- Table structure for table `users_organization`
--

CREATE TABLE `users_organization` (
  `id` int(11) NOT NULL,
  `uid` int(11) DEFAULT NULL,
  `oid` int(11) DEFAULT NULL COMMENT 'Organization ID',
  `invite_code` varchar(255) DEFAULT NULL COMMENT 'Organization Invite Code / Password',
  `account_type` tinyint(1) DEFAULT NULL COMMENT 'Account Type Inside Organization\n1- Oragnization Admin\n2- Organization User',
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='If User is part of organization here it will be connected to it';

-- --------------------------------------------------------

--
-- Table structure for table `users_sessions`
--

CREATE TABLE `users_sessions` (
  `id` int(11) NOT NULL,
  `uid` int(11) DEFAULT NULL COMMENT 'User ID',
  `session` char(64) DEFAULT NULL COMMENT 'Session Token',
  `remote_ip` varchar(45) DEFAULT NULL COMMENT 'IP used for Login',
  `created` datetime DEFAULT NULL COMMENT 'Session created Time'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Login Sessions for all users';

--
-- Indexes for dumped tables
--

--
-- Indexes for table `dataset_proportions`
--
ALTER TABLE `dataset_proportions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `proportions_uidx` (`drid`,`class_name`,`feature_set_type`,`measurement_type`,`proportion_class_name`,`value`),
  ADD KEY `proportions_idx` (`drid`,`class_name`);

--
-- Indexes for table `dataset_queue`
--
ALTER TABLE `dataset_queue`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniqueHash_UNIQUE` (`uniqueHash`),
  ADD KEY `uid_idx` (`uid`);

--
-- Indexes for table `dataset_resamples`
--
ALTER TABLE `dataset_resamples`
  ADD PRIMARY KEY (`id`),
  ADD KEY `dataset_resamples_dqidx` (`dqid`);

--
-- Indexes for table `dataset_resamples_components`
--
ALTER TABLE `dataset_resamples_components`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_class_idx` (`dqid`,`drid`,`pre_process_type`,`feature_name`,`rank_in_component`);

--
-- Indexes for table `dataset_resamples_mappings`
--
ALTER TABLE `dataset_resamples_mappings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_class_idx` (`dqid`,`drid`,`class_column`,`class_type`,`class_remapped`);

--
-- Indexes for table `models`
--
ALTER TABLE `models`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `models_unique` (`drid`,`mpid`),
  ADD KEY `models_ufidx` (`ufid`);

--
-- Indexes for table `models_packages`
--
ALTER TABLE `models_packages`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `caret_id_UNIQUE` (`internal_id`),
  ADD KEY `models_packages_methodx` (`internal_id`);

--
-- Indexes for table `models_performance`
--
ALTER TABLE `models_performance`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `model_performance_uqdx` (`mid`,`mpvid`),
  ADD KEY `model_performance_idx` (`mpvid`),
  ADD KEY `model_performance_valuex` (`prefValue`);

--
-- Indexes for table `models_performance_variables`
--
ALTER TABLE `models_performance_variables`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `model_performance_uqdx` (`value`);

--
-- Indexes for table `models_variables`
--
ALTER TABLE `models_variables`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `variables_unique_idx` (`mid`,`feature_name`),
  ADD KEY `feature_name_idx` (`feature_name`);

--
-- Indexes for table `organization`
--
ALTER TABLE `organization`
  ADD PRIMARY KEY (`id`),
  ADD KEY `organization_invite_codex` (`invite_code`);

--
-- Indexes for table `organization_details`
--
ALTER TABLE `organization_details`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `oid_UNIQUE` (`oid`);

--
-- Indexes for table `public_databases`
--
ALTER TABLE `public_databases`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `hash_UNIQUE` (`hash`);
ALTER TABLE `public_databases` ADD FULLTEXT KEY `search_idx` (`description`,`format`,`source`,`references`,`title`);

--
-- Indexes for table `public_databases_buckets`
--
ALTER TABLE `public_databases_buckets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pdmid_idx` (`pdmid`);

--
-- Indexes for table `public_databases_mappings`
--
ALTER TABLE `public_databases_mappings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_idx` (`pdid`,`position`);

--
-- Indexes for table `public_databases_statistics`
--
ALTER TABLE `public_databases_statistics`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_idx` (`pdmid`,`variable`),
  ADD KEY `pdmid_idx` (`pdmid`);

--
-- Indexes for table `public_databases_votes`
--
ALTER TABLE `public_databases_votes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_idx` (`pdid`,`uid`),
  ADD KEY `pdid_idx` (`pdid`);

--
-- Indexes for table `servers`
--
ALTER TABLE `servers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `internal_name_UNIQUE` (`server_name`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username_UNIQUE` (`username`);

--
-- Indexes for table `users_apps`
--
ALTER TABLE `users_apps`
  ADD PRIMARY KEY (`id`),
  ADD KEY `users_apps_uidx` (`uid`);

--
-- Indexes for table `users_details`
--
ALTER TABLE `users_details`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uid_UNIQUE` (`uid`);

--
-- Indexes for table `users_files`
--
ALTER TABLE `users_files`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_files_unique` (`uid`,`item_type`,`file_hash`,`file_path`),
  ADD KEY `uid_idx` (`uid`);
ALTER TABLE `users_files` ADD FULLTEXT KEY `display_filename_idx` (`display_filename`);

--
-- Indexes for table `users_files_servers`
--
ALTER TABLE `users_files_servers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users_organization`
--
ALTER TABLE `users_organization`
  ADD PRIMARY KEY (`id`),
  ADD KEY `users_organization_uidx` (`uid`);

--
-- Indexes for table `users_sessions`
--
ALTER TABLE `users_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `session_UNIQUE` (`session`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `dataset_proportions`
--
ALTER TABLE `dataset_proportions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `dataset_queue`
--
ALTER TABLE `dataset_queue`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `dataset_resamples`
--
ALTER TABLE `dataset_resamples`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `dataset_resamples_components`
--
ALTER TABLE `dataset_resamples_components`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `dataset_resamples_mappings`
--
ALTER TABLE `dataset_resamples_mappings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `models`
--
ALTER TABLE `models`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `models_packages`
--
ALTER TABLE `models_packages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `models_performance`
--
ALTER TABLE `models_performance`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `models_performance_variables`
--
ALTER TABLE `models_performance_variables`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `models_variables`
--
ALTER TABLE `models_variables`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `organization`
--
ALTER TABLE `organization`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `organization_details`
--
ALTER TABLE `organization_details`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `public_databases`
--
ALTER TABLE `public_databases`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `public_databases_buckets`
--
ALTER TABLE `public_databases_buckets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `public_databases_mappings`
--
ALTER TABLE `public_databases_mappings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `public_databases_statistics`
--
ALTER TABLE `public_databases_statistics`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `public_databases_votes`
--
ALTER TABLE `public_databases_votes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `servers`
--
ALTER TABLE `servers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users_apps`
--
ALTER TABLE `users_apps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users_details`
--
ALTER TABLE `users_details`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users_files`
--
ALTER TABLE `users_files`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users_files_servers`
--
ALTER TABLE `users_files_servers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users_organization`
--
ALTER TABLE `users_organization`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users_sessions`
--
ALTER TABLE `users_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
