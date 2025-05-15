#!/bin/bash
export LC_NUMERIC=C
# Конфигурация теста
OPT_LEVELS=("-O0" "-O1" "-O2" "-O3" "-Ofast")  # Уровни оптимизации (только для C)
SIZES=("512x512" "1024x1024" "2048x2048" "4096x4096" "8192x8192")  # Удваивающиеся размеры
RUNS=5                                        # Количество прогонов
CHANNEL=0                                     # Канал цвета (0-R, 1-G, 2-B)

# Проверка свободной памяти (в MB)
free_mem=$(free -m | awk '/Mem:/ {print $7}')

# Подготовка тестовых изображений
echo "Подготовка тестовых изображений..."
mkdir -p test_images
for size in "${SIZES[@]}"; do
    # Проверка достаточности памяти
    width=${size%x*}
    required_mem=$((width * width * 3 / 1024 / 1024 + 100))  # +100MB запаса
    
    if [ $required_mem -gt $free_mem ]; then
        echo "Пропуск $size: требуется ${required_mem}MB памяти (доступно ${free_mem}MB)"
        continue
    fi
    
    if [ ! -f "test_images/input_${size}.bmp" ]; then
        echo "Генерация $size..."
        convert -size $size -define bmp:format=bmp3 \
                gradient:blue-red "test_images/input_${size}.bmp" || {
            echo "Ошибка: Установите ImageMagick (sudo apt install imagemagick)"
            exit 1
        }
    fi
done

# Сборка ASM-версии
echo -e "\nСборка ASM-версии..."
make clean
CFLAGS="-Wall" make MODE=1 || exit 1
mv prog prog_asm

# Заголовок результатов
echo "Размер;ASM время;C -O0;C -O1;C -O2;C -O3;C -Ofast" > results.csv

# Основной цикл тестирования
for size in "${SIZES[@]}"; do
    # Пропуск если изображение не создано
    [ ! -f "test_images/input_${size}.bmp" ] && continue
    
    echo -e "\nТестирование размера $size..."
    results=("$size")
    
    # Тест ASM-версии
    asm_times=()
    for ((i=1; i<=$RUNS; i++)); do
        start=$(date +%s%N)
        ./prog_asm "test_images/input_${size}.bmp" \
            "test_images/output_asm_${size}_${i}.bmp" \
            $CHANNEL 1 || exit 1
        end=$(date +%s%N)
        duration_ns=$((end - start))
        asm_times+=($(echo "scale=6; $duration_ns / 1000000000" | bc))
    done
    asm_avg=$(echo "scale=6; (${asm_times[0]} + ${asm_times[1]} + ${asm_times[2]}) / 3" | bc)
    results+=("$asm_avg")
    
    # Тест C-версий с оптимизациями
    for opt in "${OPT_LEVELS[@]}"; do
        # Сборка если еще не собрано
        if [ ! -f "prog_c_${opt}" ]; then
            echo "Сборка C $opt..."
            make clean
            CFLAGS="$opt -Wall" make MODE=0 || exit 1
            mv prog prog_c_${opt}
        fi
        
        c_times=()
        for ((i=1; i<=$RUNS; i++)); do
            start=$(date +%s%N)
                ./prog_c_${opt} "test_images/input_${size}.bmp" \
               "test_images/output_c_${opt}_${size}_${i}.bmp" \
               $CHANNEL 0 || exit 1
            end=$(date +%s%N)
            duration_ns=$((end - start))
            c_times+=($(echo "scale=6; $duration_ns / 1000000000" | bc))
        done
        c_avg=$(echo "scale=6; (${c_times[0]} + ${c_times[1]} + ${c_times[2]}) / 3" | bc)
        results+=("$c_avg")
    done
    
    # Запись в CSV
    echo "${results[@]}" | tr ' ' ';' >> results.csv
    echo "Результаты для $size:"
    echo "ASM: ${asm_avg} сек | C: ${results[@]:2}"
done

# Итоговый отчет
echo -e "\nИтоговые результаты (среднее время в секундах):"
column -t -s';' results.csv

echo -e "\nСравнение производительности:"
tail -n +2 results.csv | while IFS=';' read size asm c_o0 c_o1 c_o2 c_o3 c_ofast; do
    best_c=$c_o0
    best_flag="-O0"

    if (( $(echo "$c_o1 < $best_c" | bc -l) )); then
        best_c=$c_o1
        best_flag="-O1"
    fi
    if (( $(echo "$c_o2 < $best_c" | bc -l) )); then
        best_c=$c_o2
        best_flag="-O2"
    fi
    if (( $(echo "$c_o3 < $best_c" | bc -l) )); then
        best_c=$c_o3
        best_flag="-O3"
    fi
    if (( $(echo "$c_ofast < $best_c" | bc -l) )); then
        best_c=$c_ofast
        best_flag="-Ofast"
    fi

    speedup=$(echo "scale=6; $best_c / $asm" | bc)
    echo "$size: ASM ${asm}сек | Лучший C $best_flag: ${best_c}сек (ASM быстрее в ${speedup}x)"
done
rm -rf test_images/
