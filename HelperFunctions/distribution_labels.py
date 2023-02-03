import os


def main():
    file_list = os.listdir('/home/pankaj/Max_of_convex_code_new/Code/output_logs/synthetic_static/')
    for item in file_list:
        filename = os.path.join('/home/pankaj/Max_of_convex_code_new/Code/output_logs/synthetic_static/', item)
        

if __name__ == '__main__':
    main()
