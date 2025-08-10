// SPDX-License-Identifier: GPL-2.0
/*
 * AXI FIFO Character Device Driver
 * Copyright (C) 2025 Scott L. McKenzie
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/device.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/platform_device.h>
#include <linux/io.h>
#include <linux/ioport.h>
#include <linux/string.h>

#define DEVICE_NAME "axi_fifo"
#define CLASS_NAME "axi_fifo_class"
#define AXI_FIFO_BASE_ADDR 0xA0020000
#define AXI_FIFO_SIZE 0x10000

// Register offsets
#define READ_DATA_REG_OFFSET    0x0000  // 0xA0020000
#define WRITE_DATA_REG_OFFSET   0x0004  // 0xA0020004
#define STATUS_REG_OFFSET       0x0008  // 0xA0020008

struct axi_fifo_dev {
    dev_t dev_num;
    struct cdev cdev;
    struct class *class;
    struct device *device;
    void __iomem *base_addr;
    struct platform_device *pdev;
    char read_command[32];
};

static struct axi_fifo_dev axi_fifo_device;

static int axi_fifo_open(struct inode *inode, struct file *file)
{
    printk(KERN_INFO "AXI FIFO: Device opened\n");
    return 0;
}

static int axi_fifo_release(struct inode *inode, struct file *file)
{
    printk(KERN_INFO "AXI FIFO: Device closed\n");
    return 0;
}

static ssize_t axi_fifo_read(struct file *file, char __user *buffer, size_t length, loff_t *offset)
{
    u32 reg_data;
    char kernel_buffer[64];
    int bytes_to_copy;

    if (*offset > 0)
    {
        return 0; // EOF
    }

    // Read data register
    reg_data = ioread32(axi_fifo_device.base_addr + READ_DATA_REG_OFFSET);
    bytes_to_copy = snprintf(kernel_buffer, sizeof(kernel_buffer), "READ_DATA: 0x%08X\n", reg_data);
    printk(KERN_INFO "AXI FIFO: Read DATA register: 0x%08X\n", reg_data);

    if (length < bytes_to_copy)
    {
        bytes_to_copy = length;
    }

    if (copy_to_user(buffer, kernel_buffer, bytes_to_copy)) 
    {
        printk(KERN_ERR "AXI FIFO: Failed to copy data to user space\n");
        return -EFAULT;
    }

    *offset += bytes_to_copy;
    return bytes_to_copy;
}

static ssize_t axi_fifo_write(struct file *file, const char __user *buffer, size_t length, loff_t *offset)
{
    char kernel_buffer[32];
    u32 write_data;
    int ret;

    if (length > sizeof(kernel_buffer) - 1)
    {
        length = sizeof(kernel_buffer) - 1;
    }

    if (copy_from_user(kernel_buffer, buffer, length)) 
    {
        printk(KERN_ERR "AXI FIFO: Failed to copy data from user space\n");
        return -EFAULT;
    }

    kernel_buffer[length] = '\0';

    // Convert string to integer (expecting hex format like "0x12345678")
    ret = kstrtou32(kernel_buffer, 0, &write_data);
    if (ret) 
    {
        printk(KERN_ERR "AXI FIFO: Invalid data format\n");
        return -EINVAL;
    }

    // Check if hardware is available (probe was called)
    if (!axi_fifo_device.base_addr) 
    {
        printk(KERN_ERR "AXI FIFO: Hardware not available - device tree entry missing\n");
        return -ENODEV;
    }

    // Write to the write data register
    iowrite32(write_data, axi_fifo_device.base_addr + WRITE_DATA_REG_OFFSET);

    printk(KERN_INFO "AXI FIFO: Wrote 0x%08X to write data register\n", write_data);

    return length;
}

static const struct file_operations axi_fifo_fops = {
    .owner = THIS_MODULE,
    .open = axi_fifo_open,
    .release = axi_fifo_release,
    .read = axi_fifo_read,
    .write = axi_fifo_write,
};

static const struct of_device_id axi_fifo_of_match[] = {
    { .compatible = "xlnx,AXI-FIFO-1.0", },
    { /* end of list */ },
};
MODULE_DEVICE_TABLE(of, axi_fifo_of_match);

static int axi_fifo_probe(struct platform_device *pdev)
{
    struct resource *res;

    printk(KERN_INFO "AXI FIFO: Probing device\n");

    axi_fifo_device.pdev = pdev;

    // Get memory resource
    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!res) 
    {
        dev_err(&pdev->dev, "No memory resource found\n");
        return -ENODEV;
    }

    // Map the memory
    axi_fifo_device.base_addr = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(axi_fifo_device.base_addr)) 
    {
        dev_err(&pdev->dev, "Failed to map memory\n");
        return PTR_ERR(axi_fifo_device.base_addr);
    }

    printk(KERN_INFO "AXI FIFO: Mapped memory at 0x%px (physical: 0x%llx)\n", axi_fifo_device.base_addr, (unsigned long long)res->start);

    return 0;
}

static int axi_fifo_remove(struct platform_device *pdev)
{
    printk(KERN_INFO "AXI FIFO: Removing device\n");
    return 0;
}

static struct platform_driver axi_fifo_driver = {
    .probe = axi_fifo_probe,
    .remove = axi_fifo_remove,
    .driver = {
        .name = DEVICE_NAME,
        .of_match_table = axi_fifo_of_match,
    },
};

static int __init axi_fifo_init(void)
{
    int ret;

    printk(KERN_INFO "AXI FIFO: Initializing driver\n");

    // Initialize read_command field
    strcpy(axi_fifo_device.read_command, "");

    // Allocate device number
    ret = alloc_chrdev_region(&axi_fifo_device.dev_num, 0, 1, DEVICE_NAME);
    if (ret < 0)
    {
        printk(KERN_ERR "AXI FIFO: Failed to allocate device number\n");
        return ret;
    }

    // Initialize character device
    cdev_init(&axi_fifo_device.cdev, &axi_fifo_fops);
    axi_fifo_device.cdev.owner = THIS_MODULE;

    // Add character device
    ret = cdev_add(&axi_fifo_device.cdev, axi_fifo_device.dev_num, 1);
    if (ret < 0) 
    {
        printk(KERN_ERR "AXI FIFO: Failed to add character device\n");
        goto cleanup_chrdev;
    }

    // Create device class
    axi_fifo_device.class = class_create(CLASS_NAME);
    if (IS_ERR(axi_fifo_device.class)) 
    {
        printk(KERN_ERR "AXI FIFO: Failed to create device class\n");
        ret = PTR_ERR(axi_fifo_device.class);
        goto cleanup_cdev;
    }

    // Create device
    axi_fifo_device.device = device_create(axi_fifo_device.class, NULL, axi_fifo_device.dev_num, NULL, DEVICE_NAME);
    if (IS_ERR(axi_fifo_device.device)) 
    {
        printk(KERN_ERR "AXI FIFO: Failed to create device\n");
        ret = PTR_ERR(axi_fifo_device.device);
        goto cleanup_class;
    }

    // Register platform driver
    ret = platform_driver_register(&axi_fifo_driver);
    if (ret < 0) 
    {
        printk(KERN_ERR "AXI FIFO: Failed to register platform driver\n");
        goto cleanup_device;
    }

    // Fallback: If no device tree entry, manually map the memory
    if (!axi_fifo_device.base_addr) 
    {
        printk(KERN_WARNING "AXI FIFO: No device tree entry found, using manual mapping\n");
        axi_fifo_device.base_addr = ioremap(AXI_FIFO_BASE_ADDR, AXI_FIFO_SIZE);
        if (!axi_fifo_device.base_addr) 
        {
            printk(KERN_ERR "AXI FIFO: Failed to manually map memory\n");
            ret = -ENOMEM;
            goto cleanup_platform;
        }
        printk(KERN_INFO "AXI FIFO: Manually mapped memory at 0x%px (physical: 0x%08X)\n", 
               axi_fifo_device.base_addr, AXI_FIFO_BASE_ADDR);
    }

    printk(KERN_INFO "AXI FIFO: Driver initialized successfully\n");
    printk(KERN_INFO "AXI FIFO: Device created at /dev/%s\n", DEVICE_NAME);
    return 0;

cleanup_platform:
    platform_driver_unregister(&axi_fifo_driver);

cleanup_device:
    device_destroy(axi_fifo_device.class, axi_fifo_device.dev_num);
cleanup_class:
    class_destroy(axi_fifo_device.class);
cleanup_cdev:
    cdev_del(&axi_fifo_device.cdev);
cleanup_chrdev:
    unregister_chrdev_region(axi_fifo_device.dev_num, 1);
    return ret;
}

static void __exit axi_fifo_exit(void)
{
    printk(KERN_INFO "AXI FIFO: Exiting driver\n");

    // Unmap memory if manually mapped
    if (axi_fifo_device.base_addr && !axi_fifo_device.pdev) 
    {
        iounmap(axi_fifo_device.base_addr);
        printk(KERN_INFO "AXI FIFO: Unmapped manually mapped memory\n");
    }

    platform_driver_unregister(&axi_fifo_driver);
    device_destroy(axi_fifo_device.class, axi_fifo_device.dev_num);
    class_destroy(axi_fifo_device.class);
    cdev_del(&axi_fifo_device.cdev);
    unregister_chrdev_region(axi_fifo_device.dev_num, 1);

    printk(KERN_INFO "AXI FIFO: Driver exited\n");
}

module_init(axi_fifo_init);
module_exit(axi_fifo_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Scott L. McKenzie");
MODULE_DESCRIPTION("AXI FIFO Character Device Driver");
MODULE_VERSION("1.0");