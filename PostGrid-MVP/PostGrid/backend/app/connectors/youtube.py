from .base import Publisher

class YoutubePublisher(Publisher):
    async def publish(self, post: dict) -> dict:
        raise NotImplementedError("Connect OAuth + official Youtube publishing API in phase 2")
