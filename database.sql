CREATE DATABASE IF NOT EXISTS `Project Deno`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `Project Deno`;

CREATE TABLE IF NOT EXISTS admins (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_admins_username (username)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS events (
  id CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  title VARCHAR(100) NOT NULL,
  category ENUM('music','arts','comedy','family') NOT NULL,
  event_date DATE NOT NULL,
  event_time TIME NULL DEFAULT NULL,
  venue VARCHAR(120) NOT NULL,
  description VARCHAR(400) NOT NULL DEFAULT '',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_events_date (event_date),
  KEY idx_events_category (category)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ticket_types (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  event_id CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  name VARCHAR(50) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY idx_ticket_types_event (event_id),
  CONSTRAINT fk_ticket_types_event FOREIGN KEY (event_id)
    REFERENCES events (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS ticket_requests (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  request_code CHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  event_title VARCHAR(100) NOT NULL,
  ticket_name VARCHAR(50) NOT NULL,
  ticket_price DECIMAL(10,2) NOT NULL,
  client_name VARCHAR(80) NOT NULL,
  client_email VARCHAR(254) NOT NULL,
  status ENUM('pending','transferred','failed') NOT NULL DEFAULT 'pending',
  email_sent TINYINT(1) NOT NULL DEFAULT 0,
  telegram_notified TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ticket_requests_code (request_code),
  KEY idx_ticket_requests_status_created (status, created_at),
  KEY idx_ticket_requests_email (client_email)
) ENGINE=InnoDB;
