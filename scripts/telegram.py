import asyncio
import os
from telethon import TelegramClient
from telethon.tl.types import MessageMediaDocument, DocumentAttributeFilename, DocumentAttributeAudio

# Замените на ваши API ID и Hash
api_id = 11846586  # Ваш API ID
api_hash = '2663a20748ebe455cf3d78ace9bbf624' # Ваш API Hash

# Имя сессии (можно любое)
session_name = 'bashdtmf'

# Папка для сохранения голосовых сообщений
DOWNLOAD_DIR = 'audio/telegram_notes' # Убедитесь, что эта папка существует

async def download_unread_voice_messages():
    """
    Подключается к Telegram, скачивает последние непрочитанные голосовые сообщения
    и сохраняет информацию о них.
    """
    print("Connecting to Telegram...")
    client = TelegramClient(session_name, api_id, api_hash)
    await client.start()
    print("Client Created")

    # Если это первый запуск, запросит код авторизации
    if not await client.is_user_authorized():
        await client.send_code_request(phone)
        try:
            await client.sign_in(phone, input('Enter the code: '))
        except SessionPasswordNeededError:
            await client.sign_in(password=input('Password: '))

    print("User authorized.")

    # Создаем папку для скачивания, если она не существует
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)

    messages_info = []

    # Получаем последние сообщения из всех диалогов
    # Можно настроить лимит сообщений или фильтровать по типу диалога
    async for dialog in client.iter_dialogs():
        # Пропускаем каналы, если не хотим из них получать сообщения
        # if dialog.is_channel:
        #     continue

        # Получаем последние непрочитанные сообщения в диалоге
        # Можно настроить лимит сообщений (limit)
        async for message in client.iter_messages(dialog.entity, :
            # Проверяем, является ли сообщение голосовым
            if message.media and isinstance(message.media, MessageMediaDocument):
                document = message.media.document
                is_voice = False
                file_name = None
                for attr in document.attributes:
                    if isinstance(attr, DocumentAttributeAudio) and attr.voice:
                        is_voice = True
                    if isinstance(attr, DocumentAttributeFilename):
                        file_name = attr.file_name

                if is_voice:
                    print(f"Found unread voice message from {dialog.name} (ID: {message.id})")
                    # Генерируем имя файла, если его нет, или используем оригинальное
                    if not file_name:
                         file_name = f"voice_message_{dialog.id}_{message.id}.ogg" # Или другое расширение
                    download_path = os.path.join(DOWNLOAD_DIR, file_name)

                    # Скачиваем файл
                    print(f"Downloading to {download_path}...")
                    await client.download_media(message, download_path)
                    print("Download complete.")

                    # Сохраняем информацию о сообщении
                    messages_info.append({
                        'file_path': download_path,
                        'chat_id': dialog.id,
                        'message_id': message.id,
                        'sender_name': dialog.name # Или message.sender.first_name и т.д.
                    })

                    # Отмечаем сообщение как прочитанное после скачивания
                    # await client.send_read_acknowledge(dialog.entity, message) # Раскомментировать, если нужно сразу отмечать как прочитанное

    await client.disconnect()
    print("Disconnected from Telegram.")

    # Здесь вы можете сохранить messages_info в файл, чтобы bash скрипт мог его прочитать
    # Например, в JSON:
    # import json
    # with open('telegram_messages.json', 'w') as f:
    #     json.dump(messages_info, f)

    return messages_info

if __name__ == '__main__':
    # Для первого запуска может потребоваться ввести номер телефона и код
    # phone = '+1234567890' # Ваш номер телефона в международном формате
    # asyncio.run(download_unread_voice_messages(phone))
    # Для последующих запусков, когда сессия уже авторизована:
    asyncio.run(download_unread_voice_messages())

