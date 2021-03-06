CROSS_COMPILE?=arm-none-eabi-

AS=$(CORSS_COMPILE)as
CC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)gcc
OBJCOPY=$(CROSS_COMPILE)objcopy
OBJDUMP=$(CROSS_COMPILE)objdump

TARGET_BIN?=main.bin
TARGET_ELF?=$(TARGET_BIN:.bin=.elf)
TARGET_DEVICE?=md

TARGET_DEVICE_CRT:=$(shell echo $(TARGET_DEVICE) | tr [:upper:] [:lower:])
TARGET_DEVICE_CRT:=startup_stm32f10x_$(TARGET_DEVICE_CRT).o

TARGET_DEVICE_DEF:=$(shell echo $(TARGET_DEVICE) | tr [:lower:] [:upper:])
TARGET_DEVICE_DEF:=STM32F10X_$(TARGET_DEVICE_DEF)

STARTUP_FILE?=$(STM32LIB)/lib/startup_stm32f10x_$(TARGET_DEVICE).o

CFLAGS?= -g -march=armv7 -mthumb -mfix-cortex-m3-ldrd -nostartfiles
STM32_CFLAGS?= -I$(STM32LIB)/inc -L$(STM32LIB)/lib -D$(TARGET_DEVICE_DEF)
STM32_LDFLAGS?=-lstm32

all:$(TARGET_BIN)
	
$(TARGET_BIN):$(TARGET_ELF)
	$(OBJCOPY) -Obinary $< $@

$(TARGET_ELF): $(OBJS) $(LDSCRIPT)
	$(LD) $(CFLAGS) $(STM32_CFLAGS) -T$(LDSCRIPT) -o $@ \
        $(STARTUP_FILE) $(filter-out $(LDSCRIPT), $^) $(STM32_LDFLAGS)

include $(OBJS:.o=.d)

%.d: %.S
	@set -e; rm -rf $@; \
	$(CC) -MM $(CPPFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

%.d: %.c
	@set -e; rm -rf $@; \
	$(CC) -MM $(CPPFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

%.o:%.c
	$(CC) -c $(CFLAGS) $(STM32_CFLAGS) -o $@ $<

objdump:$(TARGET_ELF)
	$(OBJDUMP) -xdsS $<

clean:
	-rm -rf main *.o *.d
	-rm -rf main.elf
	-rm -rf main.bin
