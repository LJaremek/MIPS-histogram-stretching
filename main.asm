.data
bufor:		.space 	4000
input_img:	.space	50		# nazwa pliku wej�ciowego
output_img: 	.space	50		# nazwa pliku wyj�ciowego
input_mess:	.asciiz ">>> Input file name: "
output_mess:	.asciiz ">>> Output file name: "
input_error:	.asciiz ">>> [-] Input image not found!"
input_info:	.asciiz ">>> [+] Input image has been opened.\n"
output_info:	.asciiz ">>> [+] Output image is ready!\n"


# ===================
# =     Legenda     =
# ===================
# $s0 -> deskryptor pliku wej�ciowego
# $s1 -> deskryptor pliku wyj�ciowego
# $s2 -> offset danych
# $s3 -> na ile fragment�w dzielimy plik do pojedycznego odczytu
# $s4 -> min pixel
# $s5 -> max pixel
# $s6 -> roznica = max_pixel - min_pixel
# $s7 -> warto�� LUT


# $t0 -> tymczasowe przechowywanie buforu
# $t1 -> ilo�� pixeli w pliku (const)
# $t2 -> wielko�� buforu (licznik)
# $t3 -> 255 (const)
# $t4 -> $s3 (licznik)
# $t5 -> 255 * 2^12 (const)
# $t6 -> pomocniczy (licznik)
# $t7 -> tymczasowe przechowywanie pixela


.text
# ===================================
# =     Wczytywanie nazw plik�w     =
# ===================================
load_input:	# Wczytywanie nazwy pliku wej�ciowego
	li	$v0, 4			# wy�wietlanie stringa
	la	$a0, input_mess		# �adowanie tekstu do wy�wietlenie
	syscall
	li	$v0, 8			# wczytywanie stringa
	la	$a0, input_img		# �adowanie tekstu do input_img
	li	$a1, 50			# �adowanie wielko�ci buforu na tekst
	syscall


find_n_1:	# Szukanie entera na ko�cu wczytanego s�owa
	lbu	$t1, 0($a0)		# �adowanie znaku wczytanego tekstu
	addi	$a0, $a0, 1		# inkrementacja znaku
	bne	$t1, '\n', find_n_1	# je�li znak != enter: skocz do szuakj_n_1

	addi	$a0, $a0, -1		# deinkrementacja znaku
	sb	$zero, 0($a0)		# zamiana znaku na 0 (znak ko�ca s�owa)


load_output:	# Wczytywanie nazwy pliku wyj�ciowego
	li	$v0, 4			# wy�wietlanie stringa
	la	$a0, output_mess	# �adowanie tekstu do wy�wietlenie
	syscall
	li	$v0, 8			# wczytywanie stringa
	la	$a0, output_img		# �adowanie tekstu do output_img
	li	$a1, 50			# �adowanie wielko�ci buforu na tekst
	syscall


find_n_2:	# Szukanie entera na ko�cu wczytanego s�owa
	lbu	$t1, 0($a0)		# �adowanie znaku wczytanego tekstu
	addi	$a0, $a0, 1		# inkrementacja znaku
	bne	$t1, '\n', find_n_2	# je�li znak != enter: skocz do szuakj_n_2

	addi	$a0, $a0, -1		# deinkrementacja znaku
	sb	$zero, 0($a0)		# zamiana znaku na 0 (znak ko�ca s�owa)



# ===================================================
# =     Analiza w�a�ciwo�ci obrazka wej�ciowego     =
# ===================================================
start:		# Otworzenie pliku
	li 	$v0, 13 		# otwieranie pliku
	la 	$a0, input_img		# �adowanie nazwy pliku
	la	$a1, 0			# flaga 0: czytanie
	li   	$a2, 0
	syscall
	move	$s0, $v0 		# zapisywanie deskryptora do $s0
	
	
	# Sprawdzanie poprawno�ci pliku
	blt	$s0, 0, fileOpenError	# je�li nie 0: b��d odczytu
	
	
	li	$v0, 4			# wy�wietlanie stringa
	la	$a0, input_info		# �adowanie informacji o otworzeniu pliku
	syscall
	
	
	# Otworzenie pliku do zapisu
	li 	$v0, 13			# otwieranie
	la 	$a0, output_img		# �adowanie nazwy pliku
	li 	$a1, 1			# flaga 1: zapisywanie
	li 	$a2, 0
	syscall
	move 	$s1, $v0 		# zapisywanie deskryptora do %s1
	
	
	# Czytanie pliku
	li 	$v0, 14			# czytanie pliku
	move 	$a0, $s0		# �adowanie deksryptora
	la 	$a1, bufor		# �adowanie buforu
	li 	$a2, 14			# �adowanie liczby znak�w do przeczytania: 14
	syscall				# pierwsze 14 bit�w to sygnatura
	la 	$t0, bufor		# �adowanie buforu do $t0
	
	
	# Czytanie ofsetu bmp
	addiu 	$t0, $t0, 10		# "popchni�cie" buforu o 10 znak�w (do ofsetu)
	lwr	$t1, ($t0)		# �adowanie 4 najbardziej znacz�ce bity
	subiu	$s2, $t1, 14		# ustawienie ofsetu w $t1 jako (bufor-14)


	# Zapisywanie pliku wyj�ciowego
	li	$v0, 15			# zapisywanie pliku
	move	$a0, $s1		# �adowanie deskryptora
	la	$a1, bufor		# �adowanie buforu
	li	$a2, 14			# �adowanie liczby znak�w do przeczytania: 14
	syscall


get_image_data:	# Czytanie pierwszej cz�ci pliku
	li	$v0, 14			# czytanie pliku
	move	$a0, $s0		# �adowanie deskryptora
	la	$a1, bufor		# �adowanie buforu
	la	$a2, 4000		# �adowanie liczby znak�w do przeczytania: 4000
	syscall
	la	$t0, bufor		# �adowanie odczytanego buforu do $t0
	
	
	# Wczytanie wielko�ci zdj�cia
	addiu	$t0, $t0, 20		# przesuniecie ofsetu o 34 ��cznie -> rozmiar obrazka
	lwr	$t1, ($t0)		# ilo�� pixeli w obrazku
	subiu 	$s3, $t1, 4014		# ilo�� pixeli - bufor - header


	# Obliczanie ilo�ci p�tli (fragment�w pliku)
	div	$s3, $s3, 4000		# dzielimy rozmiar pliku na fragmenty po 4000
	addiu	$s3, $s3, 1		# zapisanie ilo�ci p�tli (fragment�w pliku) do $s3



# ===================================================
# =     Rozpocz�cie analizowania pixeli obrazka     =
# ===================================================
histogram:
	la	$t0, bufor		# �adowanie buforu
	addu	$t0, $t0, $s2		# ustawienie $t0 jako (bufor + offset)
					# $t0 -> pierwszy pixel (lewy dolny r�g obrazka)


	# Ustawianie licznika
	li	$t6, 3999		# ilo�� pixeli bez aktualnego
	subu	$t6, $t6, $s2		# ustawienie $t6 jako (3999 - offset) -> pierwszy pixel
	lbu	$t7, ($t0)		# ustawienie $t7 jakos $t0
	move	$s5, $t7		# pierwszy pixel
	move	$s4, $t7		# pierwszy pixel
	addiu	$t0, $t0, 1		# drugi pixel



# ===============================================
# =      Szukanie min, max warto�ci pixela      =
# =                  Cz�� 1                    =
# ===============================================
find_max_min_1:	# Badanie warto�ci aktualnego pixela / ustawienie min. pixela
	lbu	$t7, ($t0)		# Ustaw $t7 jako aktualny pixel
	beqz	$t7, next_or_end	# Je�li $t7 == 0: skocz do next_or_end
	bgt	$t7, $s4, check_max_1	# Je�li $t7 >  $s4: skocz do check_max_1
	move	$s4, $t7		# Je�li $t7 <= $s4: Ustaw $s4 jako $t7


check_max_1:	# Sprawdzanie czy max. pixel / ustawienie max. pixela
	blt	$t7, $s5, next_or_end	# Je�li $77 < $s5: skocz do next_or_end
	move	$s5, $t7		# Je�li $s1 >= $s5: nadpisz $s5 = $t7


next_or_end:	# Przej�cie do kolejnego pixela / zako�czenie przeszukiwania
	addiu	$t0, $t0, 1		# Ustawia kolejny pixel
	subiu	$t6, $t6, 1		# Zmniejsza licznik
	
	bgtz	$t6, find_max_min_1	# Je�li licznik > 0: skocz do find_max_min_1
	move	$t4, $s3		# Gdy licznik == 0: $t4 = ilo��_fragment�w



# ===============================================
# =      Szukanie min, max warto�ci pixela      =
# =                  Cz�� 2                    =
# ===============================================
find_max_min_2:	# �adowanie cz�ci obrazka o rozmiarze 4000
	li	$v0, 14			# odczytywanie pliku
	move	$a0, $s0		# deskrypytor pliku
	la	$a1, bufor		# �adowanie buforu
	li	$a2, 4000		# �adowanie d�ugo�ci buforu
	syscall

	li	$t2, 4000		# �adowanie d�ugo�ci buforu do $t2
	la	$t0, bufor		# �adowanie buforu do $t0


check_max_2:	# Sprawdzanie warto�ci pixeli / ustawianie max. pixela
	lbu	$t7, ($t0)		# �adowanie pixela z buforu do $t7
	beqz	$t7, next_pixel		# je�li pixel == 0: skocz do next_pixel
	bltu	$t7, $s5, check_min_2	# je�li pixel <  $s5 (max kolor): skocz do check_min_2
	move	$s5, $t7		# je�li pixel >= $s5 (max kolor): nadpisz $s5 = $s1


check_min_2:	# Szukanie min. pixela  / ustawianie min. pixela
	bgtu	$t7, $s4, next_pixel	# je�li pixel >  $s4 (min kolor): skocz do next_pixel
	move	$s4, $t7		# je�li pixel <= $s4 (min kolor): nadpisz $s4 = $t7


next_pixel:	# Gdy pixel == 0 / Gdy znajdzie min/max pixel
	addiu	$t0, $t0, 1		# kolejny pixel z bufora
	subiu	$t2, $t2, 1		# zmniejsz numer pixela z buforu
	bgtz	$t2, check_max_2	# je�li numer pixela > 0: skocz do check_max_2


	# Wczytywanie kolejnego fragmentu pliku
	subiu	$t4, $t4, 1		# dekrementacja ilo�ci fragment�w do przejrzenia
	bgtz	$t4, find_max_min_2	# je�li licznik > 0: skocz do find_max_min_2



# =====================================
# =      Obliczanie warto�ci LUT      =
# =====================================
	sub	$s6, $s5, $s4		# $s6 = max_pixel - min_pixel = r�nica
	li	$t3, 255		# $t3 = 255

	
	sll	$t5, $t3, 12		# $t5 = 255 * 2^12
	sll	$s7, $s6, 6		# przesu� $s6 w lewo o 6  (r�nica * 2^6)
	div	$s7, $t5, $s7		# LUT = $s7 = [255*(2^12)] / [r�nica*(2^6)]



# ====================================
# =      Przygotowywanie plik�w      =
# ====================================
	li	$v0, 16			# zamykanie pliku
	move	$a0, $s0		# deksryptor pliku
	syscall


	# ponowne otwarcie pliku wej�ciowego
	li	$v0, 13			# otw�rz plik
	la	$a0, input_img		# nazwa pliku
	li	$a1, 0			# tylko do odczytu
	syscall
	move	$s0, $v0		# zapisz deksryptor do $s0
	
	
	# czytanie fragmentu pliku
	li	$v0, 14			# czytanie pliku
	move	$a0, $s0		# deskryptor pliku
	la	$a1, bufor		# bufor pliku
	la	$a2, 14			# rozmiar buforu
	syscall

	li	$v0, 14			# czytanie pliku
	move	$a0, $s0		# deskryptor pliku
	la	$a1, bufor		# bufor pliku
	la	$a2, 4000		# rozmiar buforu
	syscall


	la	$t0, bufor		# �adowanie buforu do $t0
	addu	$t0, $t0, $s2		# zwi�kszanie $t0 o offset -> przechodzenie do pixeli
	
	
	# ustawianie licznika petli
	li	$t6, 4000		# ustawianie licznika $t6 na 4000
	subu	$t6, $t6, $s2		# $t6 -= offset


	# zapisywanie do pliku wynikowego
	li	$v0, 15			# pisanie do pliku
	move	$a0, $s1		# deksryptor pliku wyj�ciowego
	la	$a1, bufor		# �adowanie buforu
	li	$a2, 4000		# �adowanie rozmiaru buforu
	syscall



# ==========================================
# =         Rozci�ganie histogramu         =
# ==========================================
read_excerpt:		# Czytanie fragmentu pliku
	li	$v0, 14			# czytanie pliku
	move	$a0, $s0		# �adowanie nazwy pliku wej�ciowego
	la	$a1, bufor		# �adowanie buforu
	li	$a2, 4000		# �adowanie wielko�ci buforu
	syscall
	li	$t2, 4000		# zapisywanie wielko�ci buforu do $t2
	la	$t0, bufor		# zapisywanie zawarto�ci buforu do $t0


calculate_lut:		# Obliczanie warto�ci tablicy LUT
	lbu	$t7, ($t0)		# �adowanie pixela
	sub	$t7, $t7, $s4		# $t7 = pixel - min_pixel
	sll	$t7, $t7, 6		# $t7 = $t7 * 2^6
	mul	$t7, $t7, $s7		# $t7 = $t7 * LUT
	sra	$t7, $t7, 12		# $t7 = $t7 / 2^12
					# dzielimy dwie linijki po mno�eniu, gdyby wysz�a za ma�a liczba


save_excerpt:		# Zapisywanie fragmentu do pliku
	sb	$t7, ($t0)		# �adowanie pixela
	addiu	$t0, $t0, 1		# �adowanie kolejnego pixela
	subiu	$t2, $t2, 1		# zmniejszanie licznika
	bgtz	$t2, calculate_lut	# je�li licznik > 0: skocz do calculate_lut
	
	li	$v0, 15			# zapisywanie do pliku wynikowego
	move	$a0, $s1		# deskryptor pliku wynikowego
	la	$a1, bufor		# �adowanie przetworzonego fragmentu
	li	$a2, 4000		# �adowanie wielko�ci przetworzonego fragmentu
	syscall

	subiu	$s3, $s3, 1		# deinkrementacja licznika p�tli fragment�w
	bgtz	$s3, read_excerpt	# je�li licznik > 0: skocz do read_excerpt


	# zamykanie plikow
	li	$v0, 16			# zamykanie pliku 
	move	$a0, $s0		# deskryptor pliku wej�ciowego
	syscall

	move	$a0, $s1		# deskryptor pliku wyj�ciowego
	syscall
	
	li	$v0, 4			# wy�wietlanie stringa
	la	$a0, output_info	# �adowanie komunikatu o wygenerowaniu outputu
	syscall


	# koniec progrmu :)
	li	$v0, 10			# najlepszy syscall na �wiecie
	syscall



# =================== Errory ===================



fileOpenError:		# nieznaleziony plik
	li	$v0, 4			# wy�wietlanie stringa
	la	$a0, input_error	# komunikat o nieistniej�cym pliku
	syscall

	li $v0, 10			# zako�czenie programu
	syscall
