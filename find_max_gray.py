

import os
import numpy as np
from PIL import Image

img_dir = "./assets"

def calculate_psychological_gray(r, g, b):
    """使用心理学公式计算灰度值: 0.299*R + 0.587*G + 0.114*B"""
    return 0.299 * r + 0.587 * g + 0.114 * b

def find_max_gray_in_image(image_path):
    """找出单张图片中的最大灰度值"""
    try:
        img = Image.open(image_path)
        img = img.convert('RGB')
        pixels = np.array(img)
        
        max_gray = 0
        for row in pixels:
            for pixel in row:
                r, g, b = pixel
                gray_value = calculate_psychological_gray(r, g, b)
                if gray_value > max_gray:
                    max_gray = gray_value
        
        return max_gray
    except Exception as e:
        print(f"处理图片 {image_path} 时出错: {e}")
        return 0

def find_max_gray_in_directory(directory):
    """找出目录中所有图片的最大灰度值"""
    max_gray_overall = 0
    image_files = []
    
    for file in os.listdir(directory):
        if file.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tiff')):
            image_files.append(file)
    
    if not image_files:
        print("在指定目录中未找到图片文件")
        return 0
    
    print(f"找到 {len(image_files)} 张图片: {image_files}")
    
    for image_file in image_files:
        image_path = os.path.join(directory, image_file)
        max_gray = find_max_gray_in_image(image_path)/255
        print(f"图片 {image_file} 的最大灰度值: {max_gray:.2f}，倒数: {1/max_gray:.2f}")
        
        if max_gray > max_gray_overall:
            max_gray_overall = max_gray
    
    return max_gray_overall

# 执行主程序
if __name__ == "__main__":
    find_max_gray_in_directory(img_dir)