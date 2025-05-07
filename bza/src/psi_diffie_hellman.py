import hashlib
import secrets


def hash_to_int(item: str) -> int:
    h = hashlib.sha256(str(item).encode()).digest()
    return int.from_bytes(h, 'big')


class DH_PSI_Party:
    """
    Party in the Diffie-Hellman based PSI protocol.
    """
    def __init__(self, p: int):
        self.p = p
        self._private_key = secrets.randbelow(p-1) + 1
    
    def prepare_items(self, items: list[str]) -> list[int]:
        """
        Prepare items for the protocol.

        Returns:
            List of hash(item)^(private_key) % p
        """
        encrypted_item_hashes = []
        for item in items:
            hashed = hash_to_int(item)
            encrypted = pow(hashed, self._private_key, self.p)
            encrypted_item_hashes.append(encrypted)
        return encrypted_item_hashes
    
    def process_received_items(self, received_items: list[int]) -> list[str]:
        """
        Process received items from the other party.

        "Double-encrypt"

        Returns:
            List of (hash(item)^(other_partys_private_key))^self.private_key % p
        """
        double_encrypted_items = []
        for received_item in received_items:
            double_encrypted_items.append(pow(received_item, self._private_key, self.p))
        return double_encrypted_items
    
    def intersection(self, my_items: list[str], my_de_items: list[str], o_de_items: list[str]) -> list[str]:
        """
        Compute the intersection of the two parties' items.

        Args:
            my_items: List of items of the party.
            my_de_items: List of double-encrypted items of the party.
            o_de_items: List of double-encrypted items of the other party.

        Returns:
            List of items that are in the intersection.
        """
        map_de_items_to_index = {item: index for index, item in enumerate(my_de_items)}
        intersection = []
        for item in set(my_de_items).intersection(set(o_de_items)):
            index = map_de_items_to_index[item]
            intersection.append(my_items[index])
        return intersection
