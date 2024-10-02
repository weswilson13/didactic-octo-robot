using LinqFaroShuffle;
using System;
using System.Collections.Generic;
using System.Linq;

namespace faroShuffle;

internal class Program {
    // Program.cs
    static void Main(string[] args)
    {
        Console.WriteLine(Suits());
        //var startingDeck = from s in Suits()
        //                from r in Ranks()
        //                select new { Suit = s, Rank = r };

        var startingDeck = Suits().SelectMany(s => Ranks().Select(r => new { Suit = s, Rank = r }));

        // Display each card that we've generated and placed in startingDeck in the console
        foreach (var card in startingDeck)
        {
            Console.WriteLine(card);
        }

        var top = startingDeck.Take(26);
        var bottom = startingDeck.Skip(26);
        var shuffle = top.InterleaveSequenceWith(bottom);

        foreach (var card in shuffle)
        {
            Console.WriteLine(card);
        }
    }

    static IEnumerable<string> Suits() 
    {
        yield return "clubs";
        yield return "hearts";
        yield return "diamonds";
        yield return "spades";
    }

    static IEnumerable<string> Ranks() 
    {
        yield return "two";
        yield return "three";
        yield return "four";
        yield return "five";
        yield return "six";
        yield return "seven";
        yield return "eight";
        yield return "nine";
        yield return "ten";
        yield return "jack";
        yield return "queen";
        yield return "king";
        yield return "ace";
    }
}